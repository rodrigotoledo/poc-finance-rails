# :nocov:
require "net/http"
require "json"
require "securerandom"

# Usage (with Docker, while `app` service is running):
#
#   docker compose run --rm app rake imports:bulk_test
#
# Override the API base URL if needed:
#
#   docker compose run --rm -e API_BASE_URL=http://localhost:3000 app rake imports:bulk_test

namespace :imports do
  desc "Upload all lib/samples files and poll until every batch completes"
  task bulk_test: :environment do
    base_url    = ENV.fetch("API_BASE_URL", "http://app:3000")
    samples_dir = Rails.root.join("lib", "samples")

    separator = "-" * 90

    puts separator
    puts "  Bulk import test"
    puts "  API: #{base_url}"
    puts "  Samples dir: #{samples_dir}"
    puts separator

    # ------------------------------------------------------------------
    # 1. Ensure the 5 sample originators exist in the database
    # ------------------------------------------------------------------
    originator_ids = ensure_sample_originators!
    puts ""

    # ------------------------------------------------------------------
    # 2. Upload every CSV / XLSX file
    # ------------------------------------------------------------------
    files = Dir.glob("#{samples_dir}/*.{csv,xlsx}").sort
    abort "No sample files found in #{samples_dir}. Run: rake samples:generate" if files.empty?

    puts "Uploading #{files.size} files to #{base_url}/api/v1/imports ...\n\n"

    batches = files.map.with_index(1) do |file_path, idx|
      originator_id = originator_ids[idx % originator_ids.size]
      response      = upload_file(base_url, file_path, originator_id)

      if response.code.to_i == 201
        batch = JSON.parse(response.body)
        printf "  [%02d] %-45s -> batch #%d  (status: %s)\n",
               idx, File.basename(file_path), batch["id"], batch["status"]
        batch
      else
        printf "  [%02d] %-45s -> FAILED (HTTP %s): %s\n",
               idx, File.basename(file_path), response.code, response.body.strip
        nil
      end
    end.compact

    if batches.empty?
      abort "\nAll uploads failed. Is the app running? Check: docker compose up"
    end

    # ------------------------------------------------------------------
    # 3. Poll until every batch reaches a terminal state
    # ------------------------------------------------------------------
    puts "\n#{separator}"
    puts "  Polling every 3 s until all batches finish..."
    puts separator

    loop do
      statuses = batches.map do |b|
        resp = http_get(base_url, "/api/v1/imports/#{b['id']}")
        JSON.parse(resp.body)
      end

      print_status_table(statuses)

      break if statuses.all? { |s| %w[completed failed].include?(s["status"]) }

      sleep 3
    end

    # ------------------------------------------------------------------
    # 4. Final summary
    # ------------------------------------------------------------------
    puts "\n#{separator}"
    puts "  Final summary"
    puts separator

    statuses = batches.map do |b|
      resp = http_get(base_url, "/api/v1/imports/#{b['id']}")
      JSON.parse(resp.body)
    end

    print_status_table(statuses)

    total_rows      = statuses.sum { |s| s["total_rows"].to_i }
    total_processed = statuses.sum { |s| s["processed_rows"].to_i }
    total_failed    = statuses.sum { |s| s["failed_rows"].to_i }
    completed       = statuses.count { |s| s["status"] == "completed" }
    failed_batches  = statuses.count { |s| s["status"] == "failed" }

    puts ""
    puts "  Batches : #{statuses.size}  (#{completed} completed, #{failed_batches} failed)"
    puts "  Rows    : #{total_rows} total / #{total_processed} processed / #{total_failed} failed"
    puts separator
  end

  # --------------------------------------------------------------------------
  # Helpers (module-level methods inside the rake task)
  # --------------------------------------------------------------------------

  def ensure_sample_originators!
    tax_ids = %w[
      12345678000195
      98765432000198
      11223344000177
      55667788000133
      99887766000111
    ]

    puts "Ensuring sample originators exist..."
    ids = tax_ids.map.with_index(1) do |tax_id, i|
      originator = Originator.kept.find_or_initialize_by(tax_id: tax_id)
      originator.legal_name ||= "Sample Originator #{i}"
      originator.save! if originator.new_record? || originator.changed?
      puts "  #{tax_id}  ->  ##{originator.id} #{originator.legal_name}"
      originator.id
    end
    ids
  end

  def upload_file(base_url, file_path, originator_id)
    uri      = URI("#{base_url}/api/v1/imports")
    boundary = "----ImportBoundary#{SecureRandom.hex(10)}"

    body = build_multipart_body(file_path, originator_id, boundary)

    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      request.body = body
      http.request(request)
    end
  end

  def http_get(base_url, path)
    uri = URI("#{base_url}#{path}")
    Net::HTTP.get_response(uri)
  end

  def build_multipart_body(file_path, originator_id, boundary)
    ext          = File.extname(file_path).downcase
    content_type = ext == ".csv" ? "text/csv" : "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    filename     = File.basename(file_path)

    parts = []

    parts << "--#{boundary}\r\n" \
             "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n" \
             "Content-Type: #{content_type}\r\n\r\n"

    body = "".b
    parts.each { |p| body << p.b }
    body << File.binread(file_path)
    body << "\r\n".b

    if originator_id
      body << "--#{boundary}\r\n".b
      body << "Content-Disposition: form-data; name=\"originator_id\"\r\n\r\n".b
      body << originator_id.to_s.b
      body << "\r\n".b
    end

    body << "--#{boundary}--\r\n".b
    body
  end

  def print_status_table(statuses)
    header = format("  %-5s  %-40s  %-11s  %8s  %10s  %8s",
                    "ID", "File", "Status", "Total", "Processed", "Failed")
    puts ""
    puts header
    puts "  " + "-" * 88

    statuses.each do |s|
      status_label = s["status"].upcase.ljust(11)
      puts format("  %-5s  %-40s  %-11s  %8s  %10s  %8s",
                  s["id"], s["filename"].to_s.slice(0, 40),
                  status_label,
                  s["total_rows"], s["processed_rows"], s["failed_rows"])
    end
  end
end
# :nocov: