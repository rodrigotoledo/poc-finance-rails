require "csv"
require "roo"

# Reads an uploaded CSV or XLSX file, splits it into chunks of CHUNK_SIZE rows,
# and enqueues one ImportChunkJob per chunk so they run in parallel.
class ProcessImportFileJob < ApplicationJob
  queue_as :imports

  CHUNK_SIZE = 1_000

  def perform(import_batch_id)
    batch = ImportBatch.find(import_batch_id)
    batch.update!(status: "processing")

    rows = load_rows(batch)

    if rows.empty?
      batch.update!(status: "failed", total_rows: 0)
      return
    end

    batch.update!(total_rows: rows.size)

    rows.each_slice(CHUNK_SIZE).with_index do |chunk, index|
      ImportChunkJob.perform_later(import_batch_id, chunk, index)
    end
  rescue => e
    ImportBatch.find_by(id: import_batch_id)&.update!(status: "failed")
    raise e
  end

  private

  def load_rows(batch)
    case batch.file_type
    when "csv"  then load_csv(batch.file_path)
    when "xlsx" then load_xlsx(batch.file_path)
    else []
    end
  end

  def load_csv(path)
    CSV.read(path, headers: true, liberal_parsing: true)
       .map(&:to_h)
  end

  def load_xlsx(path)
    spreadsheet = Roo::Excelx.new(path)
    headers = spreadsheet.row(1).map { |h| h.to_s.strip }

    (2..spreadsheet.last_row).map do |i|
      headers.zip(spreadsheet.row(i)).to_h
    end
  end
end
