# frozen_string_literal: true

class Originator < ApplicationRecord
  include Discard::Model
  include Publishable

  has_many :receivables, dependent: :restrict_with_error
  has_many :credit_operations, dependent: :restrict_with_error

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at discarded_at id legal_name tax_id updated_at]
  end

  validates :legal_name, presence: true
  validates :tax_id, presence: true, uniqueness: { conditions: -> { where(discarded_at: nil) } }
end
