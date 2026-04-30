# frozen_string_literal: true

module Api
  module V1
    class InvestmentsController < BaseController
      before_action :set_investment, only: %i[show update destroy]

      INVESTMENT_SCHEMA = {
        investor_id: Parameters.id,
        fund_id: Parameters.id,
        credit_operation_id: Parameters.id,
        investment_account_id: Parameters.id,
        amount_cents: Parameters.integer,
        interest_rate: Parameters.float,
        investment_date: Parameters.date,
        maturity_date: Parameters.date,
        status: Parameters.string
      }

      permitted_parameters :index,
                           investor_id: Parameters.id,
                           fund_id: Parameters.id,
                           credit_operation_id: Parameters.id,
                           investment_account_id: Parameters.id,
                           status: Parameters.string
      permitted_parameters :show, id: Parameters.id
      permitted_parameters :create, investment: INVESTMENT_SCHEMA
      permitted_parameters :update, id: Parameters.id, investment: INVESTMENT_SCHEMA
      permitted_parameters :destroy, id: Parameters.id

      def index
        scope = Investment.kept.includes(:investor, :fund, :credit_operation, :investment_account).order(:investment_date)
        scope = scope.where(investor_id: params[:investor_id]) if params[:investor_id].present?
        scope = scope.where(fund_id: params[:fund_id]) if params[:fund_id].present?
        scope = scope.where(credit_operation_id: params[:credit_operation_id]) if params[:credit_operation_id].present?
        scope = scope.where(investment_account_id: params[:investment_account_id]) if params[:investment_account_id].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        pagy, records = paginate_collection(scope)
        render json: { data: records, meta: pagination_meta(pagy) }
      end

      def show
        render json: @investment
      end

      def create
        investment = Investment.new(investment_params)
        apply_idempotency_key(investment)
        if investment.save
          render json: investment, status: :created
        else
          render json: { errors: investment.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotUnique
        existing = Investment.kept.find_by(idempotency_key: idempotency_key)
        raise if existing.blank?

        render json: existing, status: :ok
      end

      def update
        if @investment.update(investment_params)
          render json: @investment
        else
          render json: { errors: @investment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @investment.discard
          head :no_content
        else
          render json: { errors: @investment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_investment
        @investment = Investment.kept.find(params[:id])
      end

      def investment_params
        params.require(:investment).permit(INVESTMENT_SCHEMA)
      end
    end
  end
end
