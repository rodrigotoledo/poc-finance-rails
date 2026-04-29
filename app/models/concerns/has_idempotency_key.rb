# frozen_string_literal: true

module HasIdempotencyKey
  extend ActiveSupport::Concern

  class_methods do
    def has_idempotency_key
      if column_names.include?("discarded_at")
        validates :idempotency_key,
                  uniqueness: { conditions: -> { where(discarded_at: nil) } },
                  allow_nil: true
      else
        validates :idempotency_key, uniqueness: true, allow_nil: true
      end
    end
  end
end

