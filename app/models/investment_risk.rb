# frozen_string_literal: true

# == Schema Information
#
# Table name: investment_risks
#
#  id                  :bigint           not null, primary key
#  assessment_date     :date             not null
#  idempotency_key     :string
#  impact_cents        :bigint
#  mitigation_actions  :text
#  mitigation_status   :string           default("pending"), not null
#  probability         :decimal(5, 2)
#  risk_metrics        :jsonb            not null
#  risk_score          :decimal(5, 2)
#  risk_type           :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  credit_operation_id :bigint
#  investment_id       :bigint
#
# Indexes
#
#  index_investment_risks_on_credit_operation_id  (credit_operation_id)
#  index_investment_risks_on_idempotency_key      (idempotency_key) UNIQUE
#  index_investment_risks_on_investment_id        (investment_id)
#
# Foreign Keys
#
#  fk_rails_...  (credit_operation_id => credit_operations.id)
#  fk_rails_...  (investment_id => investments.id)
#
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
