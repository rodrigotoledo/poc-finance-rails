# frozen_string_literal: true

module Api
  module V2
    class ReceivablesController < BaseController
      before_action :set_receivable, only: %i[show update destroy]

      RECEIVABLE_SCHEMA = {
        originator_id: Parameters.id,
        reference_number: Parameters.string,
        amount_cents: Parameters.integer,
        due_on: Parameters.date,
        status: Parameters.string,
        collateral_value_cents: Parameters.integer,
        discount_rate: Parameters.float,
        risk_weight: Parameters.float
      }

      permitted_parameters :index, originator_id: Parameters.id
      permitted_parameters :show, id: Parameters.id
      permitted_parameters :create, receivable: RECEIVABLE_SCHEMA
      permitted_parameters :update, id: Parameters.id, receivable: RECEIVABLE_SCHEMA
      permitted_parameters :destroy, id: Parameters.id

      def index
        scope = Receivable.kept.joins(:originator).merge(Originator.kept)
                          .includes(:originator).order(:created_at)
        scope = scope.where(originator_id: params[:originator_id]) if params[:originator_id].present?
        render json: scope.as_json(include: { originator: { only: %i[id legal_name tax_id] } })
      end

      def show
        render json: @receivable.as_json(include: { originator: { only: %i[id legal_name tax_id] } })
      end

      def create
        receivable = Receivable.new(receivable_params)
        if receivable.save
          render json: receivable, status: :created
        else
          render json: { errors: receivable.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @receivable.update(receivable_params)
          render json: @receivable
        else
          render json: { errors: @receivable.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @receivable.discard
          head :no_content
        else
          render json: { errors: @receivable.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_receivable
        @receivable = Receivable.kept.find(params[:id])
      end

      def receivable_params
        params.require(:receivable).permit(RECEIVABLE_SCHEMA)
      end
    end
  end
end
