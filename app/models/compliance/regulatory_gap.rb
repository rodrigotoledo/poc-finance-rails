# frozen_string_literal: true

module Compliance
  class RegulatoryGap < ApplicationRecord
    self.table_name = "regulatory_gaps"

    include Discard::Model

    belongs_to :credit_operation, optional: true

    validates :area, presence: true
    validates :status, presence: true
  end
end
