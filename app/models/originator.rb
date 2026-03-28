# frozen_string_literal: true

class Originator < ApplicationRecord
  include Discard::Model

  has_many :receivables, dependent: :restrict_with_error
  has_many :credit_operations, dependent: :restrict_with_error

  validates :legal_name, presence: true
  validates :tax_id, presence: true, uniqueness: { conditions: -> { where(discarded_at: nil) } }
end
