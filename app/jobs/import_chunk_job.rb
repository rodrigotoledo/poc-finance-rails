# Processes a single chunk (up to 1_000 rows) from an ImportBatch.
# Each row is expected to map to a Receivable; rows that fail validation
# are counted as failures and their errors are persisted on the batch.
class ImportChunkJob < ApplicationJob
  queue_as :imports

  def perform(import_batch_id, rows, chunk_index)
    batch = ImportBatch.find(import_batch_id)

    chunk_processed = 0
    chunk_failed    = 0
    chunk_errors    = []

    rows.each_with_index do |row_data, row_index|
      # Row number is 1-based and accounts for the header line (+2)
      row_number = chunk_index * ProcessImportFileJob::CHUNK_SIZE + row_index + 2

      result = process_row(batch, row_data)

      if result[:ok]
        chunk_processed += 1
      else
        chunk_failed += 1
        chunk_errors << { row: row_number, errors: result[:errors] }
      end
    end

    batch.record_chunk_result!(
      chunk_processed: chunk_processed,
      chunk_failed:    chunk_failed,
      chunk_errors:    chunk_errors
    )
  end

  private

  def process_row(batch, row_data)
    originator = resolve_originator(batch, row_data)

    receivable = Receivable.new(
      originator:       originator,
      reference_number: row_data["reference_number"].to_s.strip.presence,
      amount_cents:     parse_amount_cents(row_data["amount"]),
      due_on:           row_data["due_on"],
      status:           row_data["status"].to_s.strip.presence || "pending"
    )

    if receivable.save
      { ok: true }
    else
      { ok: false, errors: receivable.errors.full_messages }
    end
  rescue => e
    { ok: false, errors: [ e.message ] }
  end

  # Prefer the row's own originator_tax_id; fall back to the batch originator.
  def resolve_originator(batch, row_data)
    tax_id = row_data["originator_tax_id"].to_s.strip.presence
    if tax_id
      Originator.kept.find_by(tax_id: tax_id)
    else
      batch.originator
    end
  end

  # Converts a decimal BRL string (e.g. "1500.50") to integer cents (150050).
  def parse_amount_cents(value)
    return nil if value.nil?

    BigDecimal(value.to_s.gsub(",", ".")) * 100
  rescue ArgumentError, TypeError
    nil
  end
end
