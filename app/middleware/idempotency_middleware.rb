# frozen_string_literal: true

require "digest"

class IdempotencyMiddleware
  HEADER_KEYS = ["Idempotency-Key", "X-Idempotency-Key"].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    return @app.call(env) unless request.post?

    key = HEADER_KEYS.lazy.map { |h| request.get_header("HTTP_#{h.upcase.tr('-', '_')}") }.find(&:present?)
    return @app.call(env) if key.blank?

    # Read and rewind the body so downstream can read it too.
    body_io = env["rack.input"]
    raw_body = body_io.read.to_s
    body_io.rewind

    request_hash = Digest::SHA256.hexdigest("#{request.request_method}\n#{request.fullpath}\n#{raw_body}")

    record = nil
    IdempotencyRequest.transaction do
      record =
        IdempotencyRequest.lock.find_by(key:, method: request.request_method, path: request.fullpath)

      if record&.completed?
        return [
          record.response_status,
          record.response_headers.merge("Content-Type" => "application/json"),
          [record.response_body.to_s]
        ]
      end

      if record.present? && !record.completed?
        return [409, { "Content-Type" => "application/json" }, ['{"error":"idempotency_key_in_progress"}']]
      end

      record = IdempotencyRequest.create!(
        key: key,
        method: request.request_method,
        path: request.fullpath,
        request_hash: request_hash
      )
    end

    status, headers, response = @app.call(env)

    response_body = +""
    response.each { |chunk| response_body << chunk.to_s }
    response.close if response.respond_to?(:close)

    record.update!(
      response_status: status,
      response_headers: safe_headers(headers),
      response_body: response_body,
      completed_at: Time.current
    )

    [status, headers, [response_body]]
  rescue ActiveRecord::RecordNotUnique
    # Another request won the race; retry to serve the stored response.
    retry
  end

  private

  def safe_headers(headers)
    # Avoid storing sensitive headers; keep only what clients may need.
    allowed = %w[Content-Type Content-Disposition]
    headers.to_h.slice(*allowed)
  end
end

