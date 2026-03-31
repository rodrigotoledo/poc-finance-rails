# frozen_string_literal: true

module Api
  module V1
    class FinancialAssetsController < BaseController
      before_action :set_asset, only: %i[show update destroy]

      def index
        scope = FinancialAsset.order(:created_at)
        scope = scope.where(originator_id: params[:originator_id]) if params[:originator_id].present?
        scope = scope.where(credit_operation_id: params[:credit_operation_id]) if params[:credit_operation_id].present?
        scope = scope.where(receivable_id: params[:receivable_id]) if params[:receivable_id].present?
        scope = scope.where(asset_type: params[:asset_type]) if params[:asset_type].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        pagy, records = paginate_collection(scope)
        render json: { data: records, meta: pagination_meta(pagy) }
      end

      def show
        render json: @asset
      end

      def create
        asset = FinancialAsset.new(asset_params)
        if asset.save
          render json: asset, status: :created
        else
          render json: { errors: asset.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @asset.update(asset_params)
          render json: @asset
        else
          render json: { errors: @asset.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @asset.destroy!
        head :no_content
      end

      private

      def set_asset
        @asset = FinancialAsset.find(params[:id])
      end

      def asset_params
        params.require(:financial_asset).permit(
          :originator_id,
          :credit_operation_id,
          :receivable_id,
          :asset_type,
          :value_cents,
          :book_value_cents,
          :market_value_cents,
          :liquidation_value_cents,
          :valuation_date,
          :status,
          valuation_metadata: {}
        )
      end
    end
  end
end
