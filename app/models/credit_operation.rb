# frozen_string_literal: true

class CreditOperation < ApplicationRecord
  include Discard::Model
  include Publishable

  STATUSES = %w[draft approved settled cancelled].freeze

  monetize :funded_amount_cents, numericality: { greater_than: 0 }

  belongs_to :receivable
  belongs_to :originator
  has_many :regulatory_gaps, class_name: "Compliance::RegulatoryGap", dependent: :nullify

  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
  validate :originator_matches_receivable

  def event_meta
    { status: status, funded_amount_cents: funded_amount_cents, rate: rate.to_s }
  end

  private

  def originator_matches_receivable
    return if receivable.blank? || originator_id.blank?

    return if receivable.originator_id == originator_id

    errors.add(:originator_id, :inconsistent_originator)
  end
end
