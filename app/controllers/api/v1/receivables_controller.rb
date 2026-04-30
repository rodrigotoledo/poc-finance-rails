# frozen_string_literal: true

module Api
  module V1
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

      permitted_parameters :index,
                           originator_id: Parameters.id,
                           status: Parameters.string,
                           q: Parameters.string
      permitted_parameters :show, id: Parameters.id
      permitted_parameters :create, receivable: RECEIVABLE_SCHEMA
      permitted_parameters :update, id: Parameters.id, receivable: RECEIVABLE_SCHEMA
      permitted_parameters :destroy, id: Parameters.id

      def index
        scope = Receivable.kept.joins(:originator).merge(Originator.kept).includes(:originator).order(:created_at)
        scope = scope.where(originator_id: params[:originator_id]) if params[:originator_id].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        if params[:q].present?
          # Use Ransack for flexible search with OR conditions
          q_params = {
            m: "or",
            reference_number_cont: params[:q],
            originator_legal_name_cont: params[:q],
            originator_tax_id_cont: params[:q]
          }
          if q_digits.present?
            q_params[:originator_tax_id_cont] = q_digits  # Also search digits
          end
          scope = scope.ransack(q_params).result
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
        apply_idempotency_key(receivable)
        if receivable.save
          render json: receivable, status: :created
        else
          render json: { errors: receivable.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotUnique
        existing = Receivable.kept.find_by(idempotency_key: idempotency_key)
        raise if existing.blank?

        render json: existing, status: :ok
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
