# frozen_string_literal: true

class InvestmentRisk < ApplicationRecord
  include HasIdempotencyKey
  include Publishable

  RISK_TYPES = %w[credit market liquidity operational legal other].freeze
  MITIGATION_STATUSES = %w[pending in_progress mitigated accepted].freeze

  belongs_to :investment, optional: true
  belongs_to :credit_operation, optional: true

  monetize :impact_cents, allow_nil: true

  validates :risk_type, presence: true, inclusion: { in: RISK_TYPES }
  validates :assessment_date, presence: true
  validates :mitigation_status, inclusion: { in: MITIGATION_STATUSES }
  validate :investment_or_credit_operation_present

  has_idempotency_key

  def event_meta
    {
      risk_type: risk_type,
      risk_score: risk_score&.to_s,
      mitigation_status: mitigation_status,
      investment_id: investment_id,
      credit_operation_id: credit_operation_id
    }
  end

  private

  def investment_or_credit_operation_present
    return if investment_id.present? || credit_operation_id.present?

    errors.add(:base, "investment or credit_operation must be present")
  end
end
