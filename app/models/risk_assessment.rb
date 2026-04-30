# frozen_string_literal: true

# == Schema Information
#
# Table name: risk_assessments
#
#  id                  :bigint           not null, primary key
#  assessment_date     :date             not null
#  assessment_details  :jsonb            not null
#  assessment_type     :string
#  expiry_date         :date
#  idempotency_key     :string
#  rating              :string
#  score               :decimal(5, 2)
#  status              :string           default("valid"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  credit_operation_id :bigint
#  originator_id       :bigint
#
# Indexes
#
#  index_risk_assessments_on_credit_operation_id  (credit_operation_id)
#  index_risk_assessments_on_idempotency_key      (idempotency_key) UNIQUE
#  index_risk_assessments_on_originator_id        (originator_id)
#  index_risk_assessments_on_status               (status)
#
# Foreign Keys
#
#  fk_rails_...  (credit_operation_id => credit_operations.id)
#  fk_rails_...  (originator_id => originators.id)
#
class RiskAssessment < ApplicationRecord
  include HasIdempotencyKey

  STATUSES = %w[valid expired superseded].freeze
  ASSESSMENT_TYPES = %w[credit_risk operational_risk concentration other].freeze

  belongs_to :credit_operation, optional: true
  belongs_to :originator, optional: true

  validates :assessment_date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :assessment_type, inclusion: { in: ASSESSMENT_TYPES }, allow_blank: true
  validate :credit_operation_or_originator_present

  has_idempotency_key

  private

  def credit_operation_or_originator_present
    return if credit_operation_id.present? || originator_id.present?

    errors.add(:base, "credit_operation or originator must be present")
  end
end
