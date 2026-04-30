# frozen_string_literal: true

# == Schema Information
#
# Table name: idempotency_requests
#
#  id               :bigint           not null, primary key
#  completed_at     :datetime
#  key              :string           not null
#  method           :string           not null
#  path             :string           not null
#  request_hash     :string           not null
#  response_body    :text
#  response_headers :jsonb            not null
#  response_status  :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_idempotency_requests_key_method_path  (key,method,path) UNIQUE
#  index_idempotency_requests_on_completed_at  (completed_at)
#
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

