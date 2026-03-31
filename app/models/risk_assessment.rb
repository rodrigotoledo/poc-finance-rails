# frozen_string_literal: true

class RiskAssessment < ApplicationRecord
  STATUSES = %w[valid expired superseded].freeze
  ASSESSMENT_TYPES = %w[credit_risk operational_risk concentration other].freeze

  belongs_to :credit_operation, optional: true
  belongs_to :originator, optional: true

  validates :assessment_date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :assessment_type, inclusion: { in: ASSESSMENT_TYPES }, allow_blank: true
  validate :credit_operation_or_originator_present

  private

  def credit_operation_or_originator_present
    return if credit_operation_id.present? || originator_id.present?

    errors.add(:base, "credit_operation or originator must be present")
  end
end
