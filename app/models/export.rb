# frozen_string_literal: true

class Export < ApplicationRecord
  include HasIdempotencyKey
  include Publishable

  STATUSES = %w[pending processing completed failed].freeze
  RANGES = %w[today yesterday week month].freeze
  ENTITIES = %w[originators receivables credit_operations regulatory_gaps imports events].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :range, inclusion: { in: RANGES }
  validates :entity, inclusion: { in: ENTITIES }

  has_idempotency_key

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

  def self.event_entity = "exports"

  def event_meta
    {
      entity: entity,
      range: range,
      filename: filename,
      row_count: row_count,
      error: error_message
    }.compact
  end

  def event_action_for_publish(default_action:, changes:)
    return "requested" if default_action == "created"

    status_change = changes["status"]
    return default_action if status_change.blank?

    next_status = status_change.last
    case next_status
    when "completed" then "completed"
    when "failed" then "failed"
    else
      nil
    end
  end
end
