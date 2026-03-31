# frozen_string_literal: true

module Api
  module V1
    class RiskAssessmentsController < BaseController
      before_action :set_assessment, only: %i[show update destroy]

      def index
        scope = RiskAssessment.order(assessment_date: :desc)
        scope = scope.where(credit_operation_id: params[:credit_operation_id]) if params[:credit_operation_id].present?
        scope = scope.where(originator_id: params[:originator_id]) if params[:originator_id].present?
        scope = scope.where(assessment_type: params[:assessment_type]) if params[:assessment_type].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        pagy, records = paginate_collection(scope)
        render json: { data: records, meta: pagination_meta(pagy) }
      end

      def show
        render json: @assessment
      end

      def create
        assessment = RiskAssessment.new(assessment_params)
        if assessment.save
          render json: assessment, status: :created
        else
          render json: { errors: assessment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @assessment.update(assessment_params)
          render json: @assessment
        else
          render json: { errors: @assessment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @assessment.destroy!
        head :no_content
      end

      private

      def set_assessment
        @assessment = RiskAssessment.find(params[:id])
      end

      def assessment_params
        params.require(:risk_assessment).permit(
          :credit_operation_id,
          :originator_id,
          :assessment_type,
          :score,
          :rating,
          :assessment_date,
          :expiry_date,
          :status,
          assessment_details: {}
        )
      end
    end
  end
end
