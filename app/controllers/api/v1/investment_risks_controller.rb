# frozen_string_literal: true

module Api
  module V1
    class InvestmentRisksController < BaseController
      before_action :set_risk, only: %i[show update destroy]

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
        if risk.save
          render json: risk, status: :created
        else
          render json: { errors: risk.errors.full_messages }, status: :unprocessable_entity
        end
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
        params.require(:investment_risk).permit(
          :investment_id,
          :credit_operation_id,
          :risk_type,
          :probability,
          :impact_cents,
          :risk_score,
          :assessment_date,
          :mitigation_status,
          :mitigation_actions,
          risk_metrics: {}
        )
      end
    end
  end
end
