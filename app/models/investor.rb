# frozen_string_literal: true

# == Schema Information
#
# Table name: investors
#
#  id              :bigint           not null, primary key
#  discarded_at    :datetime
#  idempotency_key :string
#  investor_type   :string
#  legal_name      :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  tax_id          :string           not null
#
# Indexes
#
#  index_investors_on_discarded_at     (discarded_at)
#  index_investors_on_idempotency_key  (idempotency_key) UNIQUE WHERE (discarded_at IS NULL)
#  index_investors_on_tax_id_active    (tax_id) UNIQUE WHERE (discarded_at IS NULL)
#
class Investor < ApplicationRecord
  include Discard::Model
  include HasIdempotencyKey
  include Publishable

  INVESTOR_TYPES = %w[institutional retail fund_of_funds other].freeze

  has_many :investment_accounts, dependent: :restrict_with_error
  has_many :investments, dependent: :restrict_with_error

  validates :legal_name, presence: true
  validates :tax_id, presence: true,
                     uniqueness: { conditions: -> { where(discarded_at: nil) } }
  validates :investor_type, inclusion: { in: INVESTOR_TYPES }, allow_blank: true

  has_idempotency_key

  def event_meta
    { legal_name: legal_name, tax_id: tax_id }
  end
end
