module Publishable
  extend ActiveSupport::Concern

  included do
    after_commit :publish_change
  end

  class_methods do
    def event_entity
      model_name.plural
    end
  end

  # Override in model to add context shown in the dashboard live feed.
  def event_meta
    {}
  end

  private

  def publish_change
    action = if previous_changes.key?("discarded_at") && discarded_at.present?
      "discarded"
    elsif id_previously_changed?
      "created"
    else
      "updated"
    end

    RedisPublisher.publish(
      entity:  self.class.event_entity,
      action:  action,
      id:      id,
      meta:    event_meta,
      time:    Time.current.iso8601(3)
    )
  end
end
