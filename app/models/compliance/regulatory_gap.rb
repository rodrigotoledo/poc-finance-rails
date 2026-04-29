# frozen_string_literal: true

module Compliance
  class RegulatoryGap < ApplicationRecord
    self.table_name = "regulatory_gaps"

    include Discard::Model
    include HasIdempotencyKey
    include Publishable

    def self.event_entity = "regulatory_gaps"

    belongs_to :credit_operation, optional: true

    validates :area, presence: true
    validates :status, presence: true

    has_idempotency_key
  end
end
