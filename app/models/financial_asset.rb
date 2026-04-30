# frozen_string_literal: true

# == Schema Information
#
# Table name: financial_assets
#
#  id                      :bigint           not null, primary key
#  asset_type              :string           not null
#  book_value_cents        :bigint
#  idempotency_key         :string
#  liquidation_value_cents :bigint
#  market_value_cents      :bigint
#  status                  :string           default("active"), not null
#  valuation_date          :date
#  valuation_metadata      :jsonb            not null
#  value_cents             :bigint           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  credit_operation_id     :bigint
#  originator_id           :bigint
#  receivable_id           :bigint
#
# Indexes
#
#  index_financial_assets_on_asset_type           (asset_type)
#  index_financial_assets_on_credit_operation_id  (credit_operation_id)
#  index_financial_assets_on_idempotency_key      (idempotency_key) UNIQUE
#  index_financial_assets_on_originator_id        (originator_id)
#  index_financial_assets_on_receivable_id        (receivable_id)
#  index_financial_assets_on_status               (status)
#
# Foreign Keys
#
#  fk_rails_...  (credit_operation_id => credit_operations.id)
#  fk_rails_...  (originator_id => originators.id)
#  fk_rails_...  (receivable_id => receivables.id)
#
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
