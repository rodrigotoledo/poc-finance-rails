# frozen_string_literal: true

class InvestmentAccount < ApplicationRecord
  STATUSES = %w[active suspended closed].freeze

  belongs_to :investor
  belongs_to :originator, optional: true
  has_many :investments, dependent: :restrict_with_error

  monetize :available_balance_cents
  monetize :invested_balance_cents

  validates :account_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
end
