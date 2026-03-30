# frozen_string_literal: true

require "csv"
require "active_support/core_ext/object/blank"

module Exporters
  def self.for_entity(entity)
    case entity.to_s
    when "originators" then OriginatorsExporter.new
    when "receivables" then ReceivablesExporter.new
    when "credit_operations" then CreditOperationsExporter.new
    when "regulatory_gaps" then RegulatoryGapsExporter.new
    when "imports" then ImportsExporter.new
    when "events" then EventsExporter.new
    else
      raise ArgumentError, "unsupported entity: #{entity}"
    end
  end

  def self.filename(entity:, range:)
    ts = Time.current.strftime("%Y%m%d-%H%M%S")
    "#{entity}-#{range}-#{ts}.csv"
  end

  def self.time_range_for(range_key)
    now = Time.current
    case range_key.to_s
    when "today"
      now.beginning_of_day..now.end_of_day
    when "yesterday"
      y = now.yesterday
      y.beginning_of_day..y.end_of_day
    when "week"
      (now - 7.days).beginning_of_day..now.end_of_day
    when "month"
      (now - 30.days).beginning_of_day..now.end_of_day
    else
      raise ArgumentError, "unsupported range: #{range_key}"
    end
  end

  class BaseExporter
    def export_csv(path:, range:)
      row_count = 0
      CSV.open(path, "wb", write_headers: true, headers: headers) do |csv|
        relation(range).find_each(batch_size: 1_000) do |row|
          csv << serialize(row)
          row_count += 1
        end
      end
      row_count
    end
  end

  class OriginatorsExporter < BaseExporter
    def headers = %w[id legal_name tax_id created_at]

    def relation(range)
      Originator.kept.where(created_at: range).order(:id)
    end

    def serialize(originator)
      [originator.id, originator.legal_name, originator.tax_id, originator.created_at&.iso8601]
    end
  end

  class ReceivablesExporter < BaseExporter
    def headers = %w[id reference_number originator_id amount_cents due_on status created_at]

    def relation(range)
      Receivable.kept.where(created_at: range).order(:id)
    end

    def serialize(receivable)
      [
        receivable.id,
        receivable.reference_number,
        receivable.originator_id,
        receivable.amount_cents,
        receivable.due_on,
        receivable.status,
        receivable.created_at&.iso8601
      ]
    end
  end

  class CreditOperationsExporter < BaseExporter
    def headers = %w[id receivable_id originator_id funded_amount_cents rate status created_at]

    def relation(range)
      CreditOperation.kept.where(created_at: range).order(:id)
    end

    def serialize(operation)
      [
        operation.id,
        operation.receivable_id,
        operation.originator_id,
        operation.funded_amount_cents,
        operation.rate,
        operation.status,
        operation.created_at&.iso8601
      ]
    end
  end

  class RegulatoryGapsExporter < BaseExporter
    def headers = %w[id credit_operation_id area code severity status created_at]

    def relation(range)
      Compliance::RegulatoryGap.kept.where(created_at: range).order(:id)
    end

    def serialize(gap)
      [gap.id, gap.credit_operation_id, gap.area, gap.code, gap.severity, gap.status, gap.created_at&.iso8601]
    end
  end

  class ImportsExporter < BaseExporter
    def headers = %w[id filename file_type status total_rows processed_rows failed_rows created_at]

    def relation(range)
      ImportBatch.where(created_at: range).order(:id)
    end

    def serialize(batch)
      [
        batch.id,
        batch.filename,
        batch.file_type,
        batch.status,
        batch.total_rows,
        batch.processed_rows,
        batch.failed_rows,
        batch.created_at&.iso8601
      ]
    end
  end

  class EventsExporter
    def headers = %w[stream_id time entity action id meta_json]

    def export_csv(path:, range:)
      stream_key = RedisPublisher::STREAM

      start_ms = (range.begin.to_f * 1000).floor
      end_ms = (range.end.to_f * 1000).floor
      start_id = "#{start_ms}-0"
      end_id = "#{end_ms}-999999"

      row_count = 0
      last_id = start_id

      CSV.open(path, "wb", write_headers: true, headers: headers) do |csv|
        loop do
          # XRANGE is inclusive; we use last_id and then skip it after the first page
          entries = RedisPublisher.redis.xrange(stream_key, last_id, end_id, count: 1000)
          break if entries.blank?

          entries.each_with_index do |(stream_id, fields), idx|
            next if row_count.positive? && idx.zero? && stream_id == last_id

            entity = fields["entity"]
            action = fields["action"]
            id = fields["id"]
            time = fields["time"]
            meta_json = fields["meta"]

            csv << [stream_id, time, entity, action, id, meta_json]
            row_count += 1
            last_id = stream_id
          end

          break if entries.length < 1000
        end
      end

      row_count
    end
  end
end

