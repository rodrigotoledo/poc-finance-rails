class RedisPublisher
  CHANNEL = "poc:events"

  def self.publish(payload)
    redis.publish(CHANNEL, payload.to_json)
  rescue => e
    Rails.logger.error "[RedisPublisher] #{e.message}"
  end

  def self.redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
  end
end
