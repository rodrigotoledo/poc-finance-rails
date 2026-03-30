# frozen_string_literal: true

class Export < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze
  RANGES = %w[today yesterday week month].freeze
  ENTITIES = %w[originators receivables credit_operations regulatory_gaps imports events].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :range, inclusion: { in: RANGES }
  validates :entity, inclusion: { in: ENTITIES }

  def mark_processing!
    update!(status: "processing", started_at: Time.current, error_message: nil)
  end

  def mark_completed!(filename:, file_path:, row_count:)
    update!(
      status: "completed",
      filename: filename,
      file_path: file_path,
      row_count: row_count,
      completed_at: Time.current
    )
  end

  def mark_failed!(message:)
    update!(status: "failed", error_message: message.to_s, completed_at: Time.current)
  end
end

