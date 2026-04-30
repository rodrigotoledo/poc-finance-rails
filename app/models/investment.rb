# frozen_string_literal: true

# == Schema Information
#
# Table name: investments
#
#  id                    :bigint           not null, primary key
#  amount_cents          :bigint           not null
#  discarded_at          :datetime
#  idempotency_key       :string
#  interest_rate         :decimal(7, 4)
#  investment_date       :date             not null
#  maturity_date         :date
#  status                :string           default("active"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  credit_operation_id   :bigint           not null
#  fund_id               :bigint
#  investment_account_id :bigint           not null
#  investor_id           :bigint           not null
#
# Indexes
#
#  index_investments_on_credit_operation_id    (credit_operation_id)
#  index_investments_on_discarded_at           (discarded_at)
#  index_investments_on_fund_id                (fund_id)
#  index_investments_on_idempotency_key        (idempotency_key) UNIQUE WHERE (discarded_at IS NULL)
#  index_investments_on_investment_account_id  (investment_account_id)
#  index_investments_on_investor_id            (investor_id)
#  index_investments_on_status                 (status)
#
# Foreign Keys
#
#  fk_rails_...  (credit_operation_id => credit_operations.id)
#  fk_rails_...  (fund_id => funds.id)
#  fk_rails_...  (investment_account_id => investment_accounts.id)
#  fk_rails_...  (investor_id => investors.id)
#
class Investment < ApplicationRecord
  include Discard::Model
  include HasIdempotencyKey
  include Publishable

  STATUSES = %w[active matured defaulted liquidated cancelled].freeze

  belongs_to :investor
  belongs_to :fund, optional: true
  belongs_to :credit_operation
  belongs_to :investment_account
  has_many :investment_risks, dependent: :destroy

  monetize :amount_cents, numericality: { greater_than: 0 }

  validates :investment_date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  validate :investor_matches_account

  has_idempotency_key

  def event_meta
    {
      amount_cents: amount_cents,
      credit_operation_id: credit_operation_id,
      status: status
    }
  end

  private

  def investor_matches_account
    return if investment_account.blank? || investor_id.blank?

    return if investment_account.investor_id == investor_id

    errors.add(:investment_account_id, "must belong to the same investor")
  end
end
