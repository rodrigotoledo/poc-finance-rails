# frozen_string_literal: true

class IdempotencyRequest < ApplicationRecord
  validates :key, presence: true
  validates :method, presence: true
  validates :path, presence: true
  validates :request_hash, presence: true

  validates :key, uniqueness: { scope: %i[method path] }

  def completed?
    completed_at.present?
  end
end

