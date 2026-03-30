# frozen_string_literal: true

class ExportMailer < ApplicationMailer
  def export_ready
    export = Export.find(params.fetch(:export_id))
    return unless export.status == "completed"

    to = export.deliver_to_email.presence || ENV["EXPORT_DELIVER_TO_EMAIL"].presence
    raise "EXPORT_DELIVER_TO_EMAIL not configured" if to.blank?

    attachments[export.filename.presence || "export.csv"] = File.binread(export.file_path)

    subject = "Exportação pronta (#{export.entity} · #{export.range})"
    body = +"Sua exportação está pronta.\n\n"
    body << "Entidade: #{export.entity}\n"
    body << "Período: #{export.range}\n"
    body << "Linhas: #{export.row_count}\n"
    body << "Gerado em: #{export.completed_at&.iso8601}\n"

    mail(to:, subject:, body:)
  end
end

