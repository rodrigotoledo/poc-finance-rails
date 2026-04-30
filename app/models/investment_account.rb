# frozen_string_literal: true

# == Schema Information
#
# Table name: investment_accounts
#
#  id                      :bigint           not null, primary key
#  account_number          :string           not null
#  available_balance_cents :bigint           default(0), not null
#  idempotency_key         :string
#  invested_balance_cents  :bigint           default(0), not null
#  status                  :string           default("active"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  investor_id             :bigint           not null
#  originator_id           :bigint
#
# Indexes
#
#  index_investment_accounts_on_account_number   (account_number) UNIQUE
#  index_investment_accounts_on_idempotency_key  (idempotency_key) UNIQUE
#  index_investment_accounts_on_investor_id      (investor_id)
#  index_investment_accounts_on_originator_id    (originator_id)
#
# Foreign Keys
#
#  fk_rails_...  (investor_id => investors.id)
#  fk_rails_...  (originator_id => originators.id)
#
class InvestmentAccount < ApplicationRecord
  include HasIdempotencyKey

  STATUSES = %w[active suspended closed].freeze

  belongs_to :investor
  belongs_to :originator, optional: true
  has_many :investments, dependent: :restrict_with_error

  monetize :available_balance_cents
  monetize :invested_balance_cents

  validates :account_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  has_idempotency_key
end
