# frozen_string_literal: true

# == Schema Information
#
# Table name: originators
#
#  id              :bigint           not null, primary key
#  discarded_at    :datetime
#  idempotency_key :string
#  legal_name      :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  tax_id          :string           not null
#
# Indexes
#
#  index_originators_on_discarded_at     (discarded_at)
#  index_originators_on_idempotency_key  (idempotency_key) UNIQUE WHERE (discarded_at IS NULL)
#  index_originators_on_tax_id_active    (tax_id) UNIQUE WHERE (discarded_at IS NULL)
#
class Originator < ApplicationRecord
  include Discard::Model
  include HasIdempotencyKey
  include Publishable

  has_many :receivables, dependent: :restrict_with_error
  has_many :credit_operations, dependent: :restrict_with_error

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at discarded_at id legal_name tax_id updated_at]
  end

  validates :legal_name, presence: true
  validates :tax_id, presence: true, uniqueness: { conditions: -> { where(discarded_at: nil) } }

  has_idempotency_key
end
