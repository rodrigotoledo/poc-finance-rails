# frozen_string_literal: true

class ExportMailer < ApplicationMailer
  def export_ready
    export = Export.find(params.fetch(:export_id))
    return unless export.status == "completed"

    to = export.deliver_to_email.presence || ENV["EXPORT_DELIVER_TO_EMAIL"].presence
    raise "EXPORT_DELIVER_TO_EMAIL not configured" if to.blank?

    attachments[export.filename.presence || "export.csv"] = File.binread(export.file_path)

    subject = "Exportação Concluída: #{export.entity.titleize} (#{export.range})"
    body = +"Olá,\n\n"
    body << "Sua exportação foi processada com sucesso e está anexa a este e-mail.\n\n"
    body << "Detalhes da exportação:\n"
    body << "- Entidade: #{export.entity.titleize}\n"
    body << "- Período: #{export.range}\n"
    body << "- Número de registros: #{export.row_count}\n"
    body << "- Data de conclusão: #{export.completed_at&.strftime('%d/%m/%Y às %H:%M')}\n\n"
    body << "Se você tiver alguma dúvida ou precisar de ajustes, entre em contato conosco.\n\n"
    body << "Atenciosamente,\n"
    body << "Equipe Crédito POC\n"

    mail(to:, subject:, body:)
  end
end
