# frozen_string_literal: true

class FinancialAsset < ApplicationRecord
  include HasIdempotencyKey

  STATUSES = %w[active impaired liquidated written_off].freeze
  ASSET_TYPES = %w[receivable cash collateral other].freeze

  belongs_to :originator, optional: true
  belongs_to :credit_operation, optional: true
  belongs_to :receivable, optional: true

  monetize :value_cents, numericality: { greater_than: 0 }
  monetize :book_value_cents, allow_nil: true
  monetize :market_value_cents, allow_nil: true
  monetize :liquidation_value_cents, allow_nil: true

  validates :asset_type, presence: true, inclusion: { in: ASSET_TYPES }
  validates :status, inclusion: { in: STATUSES }

  has_idempotency_key
end
