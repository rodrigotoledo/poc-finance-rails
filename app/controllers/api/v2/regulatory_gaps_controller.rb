# frozen_string_literal: true

module Api
  module V2
    class RegulatoryGapsController < BaseController
      before_action :set_regulatory_gap, only: %i[show update destroy]

      REGULATORY_GAP_SCHEMA = {
        area: Parameters.string,
        code: Parameters.string,
        description: Parameters.string,
        severity: Parameters.string,
        status: Parameters.string,
        credit_operation_id: Parameters.id
      }

      permitted_parameters :index, credit_operation_id: Parameters.id
      permitted_parameters :show, id: Parameters.id
      permitted_parameters :create, regulatory_gap: REGULATORY_GAP_SCHEMA
      permitted_parameters :update, id: Parameters.id, regulatory_gap: REGULATORY_GAP_SCHEMA
      permitted_parameters :destroy, id: Parameters.id

      def index
        scope = Compliance::RegulatoryGap.kept.order(:created_at)
        scope = scope.where(credit_operation_id: params[:credit_operation_id]) if params[:credit_operation_id].present?
        render json: scope
      end

      def show
        render json: @regulatory_gap
      end

      def create
        gap = Compliance::RegulatoryGap.new(regulatory_gap_params)
        if gap.save
          render json: gap, status: :created
        else
          render json: { errors: gap.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @regulatory_gap.update(regulatory_gap_params)
          render json: @regulatory_gap
        else
          render json: { errors: @regulatory_gap.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @regulatory_gap.discard
          head :no_content
        else
          render json: { errors: @regulatory_gap.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_regulatory_gap
        @regulatory_gap = Compliance::RegulatoryGap.kept.find(params[:id])
      end

      def regulatory_gap_params
        params.require(:regulatory_gap).permit(REGULATORY_GAP_SCHEMA)
      end
    end
  end
end
