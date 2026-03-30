# frozen_string_literal: true

module Api
  module V1
    class ReceivablesController < BaseController
      before_action :set_receivable, only: %i[show update destroy]

      def index
        scope = Receivable.kept.joins(:originator).merge(Originator.kept).includes(:originator).order(:created_at)
        scope = scope.where(originator_id: params[:originator_id]) if params[:originator_id].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        if params[:q].present?
          scope = scope.where(
            "receivables.reference_number ILIKE :q OR originators.legal_name ILIKE :q OR originators.tax_id ILIKE :q OR regexp_replace(originators.tax_id, '\\D', '', 'g') ILIKE :qd",
            q: q_like,
            qd: q_digits_like
          )
        end
        pagy, records = paginate_collection(scope)
        data = records.as_json(include: { originator: { only: %i[id legal_name tax_id] } })
        render json: { data: data, meta: pagination_meta(pagy) }
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
        params.require(:receivable).permit(:originator_id, :reference_number, :amount_cents, :due_on, :status)
      end
    end
  end
end
