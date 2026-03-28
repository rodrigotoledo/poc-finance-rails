class ImportBatch < ApplicationRecord
  STATUSES   = %w[pending processing completed failed].freeze
  FILE_TYPES = %w[csv xlsx].freeze

  belongs_to :originator, optional: true

  validates :filename,  presence: true
  validates :file_path, presence: true
  validates :file_type, inclusion: { in: FILE_TYPES }
  validates :status,    inclusion: { in: STATUSES }

  # Atomically appends errors and increments counters for one processed chunk.
  # +chunk_processed+: rows that were saved successfully.
  # +chunk_failed+:    rows that failed validation or parsing.
  # +chunk_errors+:    array of { row:, errors: [] } hashes.
  def record_chunk_result!(chunk_processed:, chunk_failed:, chunk_errors:)
    with_lock do
      self.processed_rows += chunk_processed + chunk_failed
      self.failed_rows    += chunk_failed
      self.row_errors      = (row_errors + chunk_errors).last(2_000)
      self.status          = "completed" if processed_rows >= total_rows
      save!
    end
  end
end
