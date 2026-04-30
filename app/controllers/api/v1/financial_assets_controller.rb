# frozen_string_literal: true

module Api
  module V1
    class FinancialAssetsController < BaseController
      before_action :set_asset, only: %i[show update destroy]

      FINANCIAL_ASSET_SCHEMA = {
        originator_id: Parameters.id,
        credit_operation_id: Parameters.id,
        receivable_id: Parameters.id,
        asset_type: Parameters.string,
        value_cents: Parameters.integer,
        book_value_cents: Parameters.integer,
        market_value_cents: Parameters.integer,
        liquidation_value_cents: Parameters.integer,
        valuation_date: Parameters.date,
        status: Parameters.string,
        valuation_metadata: Parameters.map
      }

      permitted_parameters :index,
                           originator_id: Parameters.id,
                           credit_operation_id: Parameters.id,
                           receivable_id: Parameters.id,
                           asset_type: Parameters.string,
                           status: Parameters.string
      permitted_parameters :show, id: Parameters.id
      permitted_parameters :create, financial_asset: FINANCIAL_ASSET_SCHEMA
      permitted_parameters :update, id: Parameters.id, financial_asset: FINANCIAL_ASSET_SCHEMA
      permitted_parameters :destroy, id: Parameters.id

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
        apply_idempotency_key(asset)
        if asset.save
          render json: asset, status: :created
        else
          render json: { errors: asset.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotUnique
        existing = FinancialAsset.find_by(idempotency_key: idempotency_key)
        raise if existing.blank?

        render json: existing, status: :ok
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
        params.require(:financial_asset).permit(FINANCIAL_ASSET_SCHEMA)
      end
    end
  end
end
