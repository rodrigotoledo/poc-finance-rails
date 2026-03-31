# frozen_string_literal: true

class Investor < ApplicationRecord
  include Discard::Model
  include Publishable

  INVESTOR_TYPES = %w[institutional retail fund_of_funds other].freeze

  has_many :investment_accounts, dependent: :restrict_with_error
  has_many :investments, dependent: :restrict_with_error

  validates :legal_name, presence: true
  validates :tax_id, presence: true,
                     uniqueness: { conditions: -> { where(discarded_at: nil) } }
  validates :investor_type, inclusion: { in: INVESTOR_TYPES }, allow_blank: true

  def event_meta
    { legal_name: legal_name, tax_id: tax_id }
  end
end
