# frozen_string_literal: true

module Api
  module V1
    class InvestmentRisksController < BaseController
      before_action :set_risk, only: %i[show update destroy]

      INVESTMENT_RISK_SCHEMA = {
        investment_id: Parameters.id,
        credit_operation_id: Parameters.id,
        risk_type: Parameters.string,
        probability: Parameters.float,
        impact_cents: Parameters.integer,
        risk_score: Parameters.float,
        assessment_date: Parameters.date,
        mitigation_status: Parameters.string,
        mitigation_actions: Parameters.string,
        risk_metrics: Parameters.map
      }

      permitted_parameters :index,
                           investment_id: Parameters.id,
                           credit_operation_id: Parameters.id,
                           risk_type: Parameters.string
      permitted_parameters :show, id: Parameters.id
      permitted_parameters :create, investment_risk: INVESTMENT_RISK_SCHEMA
      permitted_parameters :update, id: Parameters.id, investment_risk: INVESTMENT_RISK_SCHEMA
      permitted_parameters :destroy, id: Parameters.id

      def index
        scope = InvestmentRisk.order(:assessment_date)
        scope = scope.where(investment_id: params[:investment_id]) if params[:investment_id].present?
        scope = scope.where(credit_operation_id: params[:credit_operation_id]) if params[:credit_operation_id].present?
        scope = scope.where(risk_type: params[:risk_type]) if params[:risk_type].present?
        pagy, records = paginate_collection(scope)
        render json: { data: records, meta: pagination_meta(pagy) }
      end

      def show
        render json: @risk
      end

      def create
        risk = InvestmentRisk.new(risk_params)
        apply_idempotency_key(risk)
        if risk.save
          render json: risk, status: :created
        else
          render json: { errors: risk.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotUnique
        existing = InvestmentRisk.find_by(idempotency_key: idempotency_key)
        raise if existing.blank?

        render json: existing, status: :ok
      end

      def update
        if @risk.update(risk_params)
          render json: @risk
        else
          render json: { errors: @risk.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @risk.destroy!
        head :no_content
      end

      private

      def set_risk
        @risk = InvestmentRisk.find(params[:id])
      end

      def risk_params
        params.require(:investment_risk).permit(INVESTMENT_RISK_SCHEMA)
      end
    end
  end
end
