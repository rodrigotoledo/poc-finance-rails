# frozen_string_literal: true

module Api
  module V1
    class FundsController < BaseController
      before_action :set_fund, only: %i[show update destroy]

      FUND_SCHEMA = {
        name: Parameters.string,
        fund_type: Parameters.string,
        total_commitment_cents: Parameters.integer,
        allocated_amount_cents: Parameters.integer,
        available_amount_cents: Parameters.integer,
        inception_date: Parameters.date,
        maturity_date: Parameters.date,
        target_return_rate: Parameters.float,
        status: Parameters.string
      }

      permitted_parameters :dashboard, {}
      permitted_parameters :index, {}
      permitted_parameters :show, id: Parameters.id
      permitted_parameters :create, fund: FUND_SCHEMA
      permitted_parameters :update, id: Parameters.id, fund: FUND_SCHEMA
      permitted_parameters :destroy, id: Parameters.id

      # GET /api/v1/funds/dashboard — agregados financeiros e riscos ligados a investimentos com fundo.
      def dashboard
        funds_scope = Fund.all
        investments_with_fund = Investment.where.not(fund_id: nil)
        risks_scope = InvestmentRisk.joins(:investment).where.not(investments: { fund_id: nil })

        render json: {
          funds_count: funds_scope.count,
          by_status: funds_scope.group(:status).count.transform_values(&:to_i),
          totals: {
            total_commitment_cents: funds_scope.sum(:total_commitment_cents).to_i,
            total_allocated_cents: funds_scope.sum(:allocated_amount_cents).to_i,
            total_available_cents: funds_scope.where.not(available_amount_cents: nil).sum(:available_amount_cents).to_i
          },
          investments_via_funds: {
            count: investments_with_fund.count,
            total_amount_cents: investments_with_fund.sum(:amount_cents).to_i
          },
          risks_for_funds: {
            count: risks_scope.count,
            by_risk_type: risks_scope.group(:risk_type).count.transform_values(&:to_i),
            avg_risk_score: risks_scope.average("investment_risks.risk_score")&.to_f&.round(4),
            pending_mitigation_count: risks_scope.where(mitigation_status: "pending").count
          }
        }
      end

      def index
        scope = Fund.order(:created_at)
        scope = scope.where(status: params[:status]) if params[:status].present?
        if params[:q].present?
          q = "%#{params[:q].to_s.strip}%"
          scope = scope.where("name ILIKE :q", q: q)
        end
        pagy, records = paginate_collection(scope)
        render json: { data: records, meta: pagination_meta(pagy) }
      end

      def show
        render json: @fund
      end

      def create
        fund = Fund.new(fund_params)
        apply_idempotency_key(fund)
        if fund.save
          render json: fund, status: :created
        else
          render json: { errors: fund.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotUnique
        existing = Fund.find_by(idempotency_key: idempotency_key)
        raise if existing.blank?

        render json: existing, status: :ok
      end

      def update
        if @fund.update(fund_params)
          render json: @fund
        else
          render json: { errors: @fund.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @fund.destroy
          head :no_content
        else
          render json: { errors: @fund.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_fund
        @fund = Fund.find(params[:id])
      end

      def fund_params
        params.require(:fund).permit(FUND_SCHEMA)
      end
    end
  end
end
