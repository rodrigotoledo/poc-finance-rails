# frozen_string_literal: true

module Api
  module V1
    class InvestmentAccountsController < BaseController
      before_action :set_account, only: %i[show update destroy]

      def index
        scope = InvestmentAccount.order(:created_at)
        scope = scope.where(investor_id: params[:investor_id]) if params[:investor_id].present?
        scope = scope.where(originator_id: params[:originator_id]) if params[:originator_id].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        pagy, records = paginate_collection(scope)
        render json: { data: records, meta: pagination_meta(pagy) }
      end

      def show
        render json: @account
      end

      def create
        account = InvestmentAccount.new(account_params)
        if account.save
          render json: account, status: :created
        else
          render json: { errors: account.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @account.update(account_params)
          render json: @account
        else
          render json: { errors: @account.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @account.destroy
          head :no_content
        else
          render json: { errors: @account.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_account
        @account = InvestmentAccount.find(params[:id])
      end

      def account_params
        params.require(:investment_account).permit(
          :investor_id,
          :originator_id,
          :account_number,
          :available_balance_cents,
          :invested_balance_cents,
          :status
        )
      end
    end
  end
end
