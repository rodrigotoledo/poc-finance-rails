# frozen_string_literal: true

module Api
  module V2
    class CreditOperationsController < BaseController
      before_action :set_credit_operation, only: %i[show update destroy]

      CREDIT_OPERATION_SCHEMA = {
        receivable_id: Parameters.id,
        originator_id: Parameters.id,
        funded_amount_cents: Parameters.integer,
        rate: Parameters.float,
        status: Parameters.string,
        total_invested_cents: Parameters.integer,
        available_for_investment_cents: Parameters.integer,
        investment_start_date: Parameters.date,
        investment_end_date: Parameters.date,
        risk_rating: Parameters.string,
        expected_return_rate: Parameters.float
      }

      permitted_parameters :index,
                           originator_id: Parameters.id,
                           receivable_id: Parameters.id
      permitted_parameters :show, id: Parameters.id
      permitted_parameters :create, credit_operation: CREDIT_OPERATION_SCHEMA
      permitted_parameters :update, id: Parameters.id, credit_operation: CREDIT_OPERATION_SCHEMA
      permitted_parameters :destroy, id: Parameters.id

      def index
        scope = CreditOperation.kept
                               .joins(:receivable, :originator)
                               .merge(Receivable.kept).merge(Originator.kept)
                               .includes(:receivable, :originator)
                               .order(:created_at)
        scope = scope.where(originator_id: params[:originator_id]) if params[:originator_id].present?
        scope = scope.where(receivable_id: params[:receivable_id]) if params[:receivable_id].present?
        render json: scope.as_json(
          include: {
            receivable: { only: %i[id reference_number amount_cents due_on status] },
            originator: { only: %i[id legal_name tax_id] }
          }
        )
      end

      def show
        render json: @credit_operation.as_json(
          include: {
            receivable: { only: %i[id reference_number amount_cents due_on status] },
            originator: { only: %i[id legal_name tax_id] }
          }
        )
      end

      def create
        operation = CreditOperation.new(credit_operation_params)
        if operation.save
          render json: operation, status: :created
        else
          render json: { errors: operation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @credit_operation.update(credit_operation_params)
          render json: @credit_operation
        else
          render json: { errors: @credit_operation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @credit_operation.discard
          head :no_content
        else
          render json: { errors: @credit_operation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_credit_operation
        @credit_operation = CreditOperation.kept.find(params[:id])
      end

      def credit_operation_params
        params.require(:credit_operation).permit(CREDIT_OPERATION_SCHEMA)
      end
    end
  end
end
