# frozen_string_literal: true

# == Schema Information
#
# Table name: funds
#
#  id                     :bigint           not null, primary key
#  allocated_amount_cents :bigint           default(0), not null
#  available_amount_cents :bigint
#  fund_type              :string
#  idempotency_key        :string
#  inception_date         :date
#  maturity_date          :date
#  name                   :string           not null
#  status                 :string           default("active"), not null
#  target_return_rate     :decimal(7, 4)
#  total_commitment_cents :bigint
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_funds_on_idempotency_key  (idempotency_key) UNIQUE
#  index_funds_on_status           (status)
#
class Fund < ApplicationRecord
  include HasIdempotencyKey
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

  has_idempotency_key

  def event_meta
    {
      name: name,
      status: status,
      allocated_amount_cents: allocated_amount_cents
    }
  end
end
