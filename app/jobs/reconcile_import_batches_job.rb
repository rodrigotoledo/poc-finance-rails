# frozen_string_literal: true

# Keeps ImportBatch statuses consistent with reality.
# - If a batch is pending and the file exists, enqueue processing.
# - If a batch is pending/processing but the file is missing, mark as failed.
class ReconcileImportBatchesJob < ApplicationJob
  queue_as :default

  LIMIT = 200

  def perform
    return unless enabled?

    mark_missing_files_failed!
    enqueue_pending_with_file!
  end

  private

  def enabled?
    ENV.fetch("IMPORT_RECONCILE_ENABLED", "1") == "1"
  end

  def mark_missing_files_failed!
    ImportBatch
      .where(status: %w[pending processing])
      .order(:id)
      .limit(LIMIT)
      .each do |batch|
        next if batch.file_path.present? && File.exist?(batch.file_path)

        batch.update!(
          status: "failed",
          total_rows: (batch.total_rows || 0),
          processed_rows: (batch.processed_rows || 0)
        )
      rescue => e
        Rails.logger.warn("[ReconcileImportBatchesJob] batch=#{batch.id} #{e.class}: #{e.message}")
      end
  end

  def enqueue_pending_with_file!
    ImportBatch
      .where(status: "pending")
      .order(:id)
      .limit(LIMIT)
      .each do |batch|
        next unless batch.file_path.present? && File.exist?(batch.file_path)

        ProcessImportFileJob.perform_later(batch.id)
      rescue => e
        Rails.logger.warn("[ReconcileImportBatchesJob] enqueue batch=#{batch.id} #{e.class}: #{e.message}")
      end
  end
end

