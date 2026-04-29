# frozen_string_literal: true

module Publishable
  extend ActiveSupport::Concern

  included do
    after_commit :publish_created_event, on: :create
    after_commit :publish_updated_event, on: :update
    after_commit :publish_destroyed_event, on: :destroy
  end

  class_methods do
    def event_entity = model_name.plural
  end

  def event_entity
    self.class.event_entity
  end

  def event_meta
    {}
  end

  def event_action_for_publish(default_action:, changes:)
    return "discarded" if changes.key?("discarded_at") && changes["discarded_at"]&.last.present?

    default_action
  end

  private

  def publish_created_event
    publish_event(default_action: "created")
  end

  def publish_updated_event
    publish_event(default_action: "updated")
  end

  def publish_destroyed_event
    publish_event(default_action: "discarded")
  end

  def publish_event(default_action:)
    changes = previous_changes
    action = event_action_for_publish(default_action: default_action, changes: changes)
    return if action.nil?

    event = {
      entity: event_entity,
      action: action,
      id: id,
      meta: event_meta,
      time: Time.current.iso8601
    }

    RedisPublisher.publish(event)
  rescue StandardError
    # Events are best-effort; publishing must never break the request cycle.
    nil
  end
end
