# frozen_string_literal: true

class Investment < ApplicationRecord
  include Discard::Model
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
