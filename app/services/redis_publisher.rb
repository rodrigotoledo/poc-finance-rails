# frozen_string_literal: true

class RedisPublisher
  CHANNEL = "poc:events"
  STREAM  = "poc:events:stream"

  def self.publish(payload)
    json = payload.to_json
    redis.publish(CHANNEL, json)
    publish_stream(payload)
  rescue StandardError => e
    Rails.logger.error "[RedisPublisher] #{e.message}"
  end

  def self.publish_stream(payload)
    entry = {
      event:  "#{payload[:entity]}.#{payload[:action]}",
      entity: payload[:entity].to_s,
      action: payload[:action].to_s,
      id:     payload[:id].to_s,
      time:   payload[:time].to_s,
      meta:   payload[:meta].to_json
    }

    redis.xadd(STREAM, entry, maxlen: stream_maxlen, approximate: true)
  rescue StandardError => e
    Rails.logger.error "[RedisPublisher:stream] #{e.message}"
  end

  def self.redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://redis:6379/0"))
  end

  def self.stream_maxlen
    Integer(ENV.fetch("REDIS_STREAM_MAXLEN", 50_000))
  rescue ArgumentError
    50_000
  end
end
