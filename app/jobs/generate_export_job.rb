# frozen_string_literal: true

class GenerateExportJob < ApplicationJob
  queue_as :exports

  def perform(export_id)
    export = Export.find(export_id)
    export.mark_processing!

    exporter = Exporters.for_entity(export.entity)
    range = Exporters.time_range_for(export.range)

    filename = Exporters.filename(entity: export.entity, range: export.range)
    dir = Rails.root.join("tmp", "exports")
    FileUtils.mkdir_p(dir)
    path = dir.join("#{export.id}-#{filename}")

    row_count = exporter.export_csv(path:, range:)

    export.mark_completed!(filename: filename, file_path: path.to_s, row_count: row_count)

    ExportMailer.with(export_id: export.id).export_ready.deliver_later

    RedisPublisher.publish(
      entity: "exports",
      action: "completed",
      id: export.id,
      time: Time.current.iso8601,
      meta: {
        entity: export.entity,
        range: export.range,
        filename: export.filename,
        row_count: export.row_count,
        deliver_to_email: export.deliver_to_email
      }
    )
  rescue => e
    begin
      Export.find(export_id).mark_failed!(message: e.message)
    rescue
      # ignore
    end

    RedisPublisher.publish(
      entity: "exports",
      action: "failed",
      id: export_id,
      time: Time.current.iso8601,
      meta: { error: e.message }
    )
    raise
  end
end

