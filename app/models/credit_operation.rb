# frozen_string_literal: true

class CreditOperation < ApplicationRecord
  include Discard::Model
  include HasIdempotencyKey
  include Publishable

  STATUSES = %w[draft approved settled cancelled].freeze

  monetize :funded_amount_cents, numericality: { greater_than: 0 }

  belongs_to :receivable
  belongs_to :originator
  has_many :regulatory_gaps, class_name: "Compliance::RegulatoryGap", dependent: :nullify
  has_many :investments, dependent: :restrict_with_error
  has_many :investment_risks, dependent: :destroy
  has_many :financial_assets, dependent: :destroy
  has_many :risk_assessments, dependent: :destroy

  monetize :total_invested_cents, numericality: { greater_than_or_equal_to: 0 }
  monetize :available_for_investment_cents, allow_nil: true

  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
  validate :originator_matches_receivable

  def event_meta
    { status: status, funded_amount_cents: funded_amount_cents, rate: rate.to_s }
  end

  def funding_gap
    funded_amount_cents - total_invested_cents
  end

  def utilization_rate
    return 0 if funded_amount_cents.zero?

    (total_invested_cents.to_f / funded_amount_cents) * 100
  end

  has_idempotency_key

  private

  def originator_matches_receivable
    return if receivable.blank? || originator_id.blank?

    return if receivable.originator_id == originator_id

    errors.add(:originator_id, :inconsistent_originator)
  end
end
