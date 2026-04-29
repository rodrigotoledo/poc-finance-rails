# frozen_string_literal: true

class Receivable < ApplicationRecord
  include Discard::Model
  include HasIdempotencyKey
  include Publishable

  STATUSES = %w[pending eligible advanced cancelled].freeze

  monetize :amount_cents, numericality: { greater_than: 0 }

  belongs_to :originator
  has_many :credit_operations, dependent: :restrict_with_error
  has_many :financial_assets, dependent: :destroy

  monetize :collateral_value_cents, allow_nil: true

  def self.ransackable_attributes(auth_object = nil)
    %w[amount_cents created_at discarded_at due_on id originator_id reference_number status updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[originator]
  end

  def event_meta
    { status: status, amount_cents: amount_cents, due_on: due_on.to_s }
  end

  validates :reference_number, presence: true,
                               uniqueness: { scope: :originator_id, conditions: -> { where(discarded_at: nil) } }
  validates :due_on, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :discount_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :risk_weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  has_idempotency_key
end
