# frozen_string_literal: true

module Api
  module V1
    class InvestorsController < BaseController
      before_action :set_investor, only: %i[show update destroy]

      def index
        scope = Investor.kept.order(:created_at)
        if params[:q].present?
          scope = scope.where(
            "legal_name ILIKE :q OR tax_id ILIKE :q OR regexp_replace(tax_id, '\\D', '', 'g') ILIKE :qd",
            q: q_like,
            qd: q_digits_like
          )
        end
        pagy, records = paginate_collection(scope)
        render json: { data: records, meta: pagination_meta(pagy) }
      end

      def show
        render json: @investor
      end

      def create
        investor = Investor.new(investor_params)
        if investor.save
          render json: investor, status: :created
        else
          render json: { errors: investor.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @investor.update(investor_params)
          render json: @investor
        else
          render json: { errors: @investor.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @investor.discard
          head :no_content
        else
          render json: { errors: @investor.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_investor
        @investor = Investor.kept.find(params[:id])
      end

      def investor_params
        params.require(:investor).permit(:legal_name, :tax_id, :investor_type)
      end
    end
  end
end
