# frozen_string_literal: true

module Api
  module V1
    class InvestorsController < BaseController
      before_action :set_investor, only: %i[show update destroy]

      INVESTOR_SCHEMA = {
        legal_name: Parameters.string,
        tax_id: Parameters.string,
        investor_type: Parameters.string
      }

      permitted_parameters :index, {}
      permitted_parameters :show, id: Parameters.id
      permitted_parameters :create, investor: INVESTOR_SCHEMA
      permitted_parameters :update, id: Parameters.id, investor: INVESTOR_SCHEMA
      permitted_parameters :destroy, id: Parameters.id

      def index
        scope = Investor.kept.order(:created_at)
        if params[:q].present?
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
        render json: @investor
      end

      def create
        investor = Investor.new(investor_params)
        apply_idempotency_key(investor)
        if investor.save
          render json: investor, status: :created
        else
          render json: { errors: investor.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotUnique
        existing = Investor.kept.find_by(idempotency_key: idempotency_key)
        raise if existing.blank?

        render json: existing, status: :ok
      end

      def update
        if @investor.update(investor_params)
          render json: @investor
        else
          render json: { errors: @investor.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @investor.discard
          head :no_content
        else
          render json: { errors: @investor.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_investor
        @investor = Investor.kept.find(params[:id])
      end

      def investor_params
        params.require(:investor).permit(INVESTOR_SCHEMA)
      end
    end
  end
end
