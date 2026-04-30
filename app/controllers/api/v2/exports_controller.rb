# frozen_string_literal: true

module Api
  module V2
    class ExportsController < BaseController
      permitted_parameters :create,
                           entity: Parameters.string.required,
                           range: Parameters.string.required,
                           deliver_to_email: Parameters.string
      permitted_parameters :show, id: Parameters.id

      def create
        export = Export.create!(
          entity: params.require(:entity),
          range: params.require(:range),
          requested_by_email: request.headers["X-User-Email"],
          deliver_to_email: params[:deliver_to_email].presence || ENV["EXPORT_DELIVER_TO_EMAIL"]
        )

        GenerateExportJob.perform_async(export.id)

        RedisPublisher.publish(
          entity: "exports",
          action: "requested",
          id: export.id,
          time: Time.current.iso8601(3),
          meta: {
            entity: export.entity,
            range: export.range,
            deliver_to_email: export.deliver_to_email
          }
        )

        render json: { id: export.id, status: export.status }, status: :accepted
      end

      def show
        export = Export.find(params[:id])
        render json: export.as_json(only: %i[id entity range status filename row_count error_message created_at started_at completed_at])
      end
    end
  end
end

