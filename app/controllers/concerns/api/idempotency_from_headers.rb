# frozen_string_literal: true

module Api
  module IdempotencyFromHeaders
    private

    def idempotency_key
      request.headers["Idempotency-Key"].presence || request.headers["X-Idempotency-Key"].presence
    end

    def apply_idempotency_key(record)
      key = idempotency_key
      return if key.blank?

      record.idempotency_key ||= key
    end
  end
end

