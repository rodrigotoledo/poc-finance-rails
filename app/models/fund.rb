# frozen_string_literal: true

class Fund < ApplicationRecord
  include Publishable

  STATUSES = %w[active closed winding_up].freeze
  FUND_TYPES = %w[equity debt mixed other].freeze

  has_many :investments, dependent: :restrict_with_error

  monetize :total_commitment_cents, allow_nil: true
  monetize :allocated_amount_cents
  monetize :available_amount_cents, allow_nil: true

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :fund_type, inclusion: { in: FUND_TYPES }, allow_blank: true
  validates :target_return_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def event_meta
    {
      name: name,
      status: status,
      allocated_amount_cents: allocated_amount_cents
    }
  end
end
