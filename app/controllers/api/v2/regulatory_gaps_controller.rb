# frozen_string_literal: true

module Api
  module V2
    class RegulatoryGapsController < BaseController
      before_action :set_regulatory_gap, only: %i[show update destroy]

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
        params.require(:regulatory_gap).permit(:area, :code, :description, :severity, :status, :credit_operation_id)
      end
    end
  end
end
