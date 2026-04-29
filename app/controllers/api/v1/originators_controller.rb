# frozen_string_literal: true

module Api
  module V1
    class OriginatorsController < BaseController
      before_action :set_originator, only: %i[show update destroy]

      def index
        scope = Originator.kept.order(:created_at)
        if params[:q].present?
          # Use Ransack for flexible search with OR conditions
          q_params = {
            m: "or",
            legal_name_cont: params[:q],
            tax_id_cont: params[:q]
          }
          if q_digits.present?
            q_params[:tax_id_cont] = q_digits  # Also search digits
          end
          scope = scope.ransack(q_params).result
        end
        pagy, records = paginate_collection(scope)
        render json: { data: records, meta: pagination_meta(pagy) }
      end

      def show
        render json: @originator
      end

      def create
        originator = Originator.new(originator_params)
        apply_idempotency_key(originator)
        if originator.save
          render json: originator, status: :created
        else
          render json: { errors: originator.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotUnique
        existing = Originator.kept.find_by(idempotency_key: idempotency_key)
        raise if existing.blank?

        render json: existing, status: :ok
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
