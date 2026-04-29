require "sidekiq-scheduler"

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  unless Rails.env.test?
    require "sidekiq-unique-jobs"

    config.client_middleware do |chain|
      chain.add SidekiqUniqueJobs::Middleware::Client
    end

    config.server_middleware do |chain|
      chain.add SidekiqUniqueJobs::Middleware::Server
    end

    SidekiqUniqueJobs::Server.configure(config)
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  unless Rails.env.test?
    require "sidekiq-unique-jobs"

    config.client_middleware do |chain|
      chain.add SidekiqUniqueJobs::Middleware::Client
    end
  end
end

unless Rails.env.test?
  SidekiqUniqueJobs.configure do |config|
    config.logger_enabled = true
    config.on_conflict = {
      client: :log,
      server: :log
    }
  end
end
