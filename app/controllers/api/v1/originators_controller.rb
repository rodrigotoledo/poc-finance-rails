# frozen_string_literal: true

module Api
  module V1
    class OriginatorsController < BaseController
      before_action :set_originator, only: %i[show update destroy]

      def index
        scope = Originator.kept.order(:created_at)
        if params[:q].present?
          # Accept masked inputs (e.g. "12.345.678/0001-90") by comparing digits-only too.
          scope = scope.where(
            "legal_name ILIKE :q OR tax_id ILIKE :q OR regexp_replace(tax_id, '\\D', '', 'g') ILIKE :qd",
            q: q_like,
            qd: q_digits_like
          )
        end
        pagy, records = paginate_collection(scope)
        render json: { data: records, meta: pagination_meta(pagy) }
      end

      def show
        render json: @originator
      end

      def create
        originator = Originator.new(originator_params)
        if originator.save
          render json: originator, status: :created
        else
          render json: { errors: originator.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @originator.update(originator_params)
          render json: @originator
        else
          render json: { errors: @originator.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @originator.discard
          head :no_content
        else
          render json: { errors: @originator.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_originator
        @originator = Originator.kept.find(params[:id])
      end

      def originator_params
        params.require(:originator).permit(:legal_name, :tax_id)
      end
    end
  end
end
