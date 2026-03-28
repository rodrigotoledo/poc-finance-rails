# frozen_string_literal: true

class Receivable < ApplicationRecord
  include Discard::Model

  STATUSES = %w[pending eligible advanced cancelled].freeze

  monetize :amount_cents, numericality: { greater_than: 0 }

  belongs_to :originator
  has_many :credit_operations, dependent: :restrict_with_error

  validates :reference_number, presence: true,
                               uniqueness: { scope: :originator_id, conditions: -> { where(discarded_at: nil) } }
  validates :due_on, presence: true
  validates :status, inclusion: { in: STATUSES }
end
