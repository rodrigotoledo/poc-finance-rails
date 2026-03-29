# CORS — Next.js (port 3001) calls Rails directly for CRUD (API v1/v2).
# NestJS does NOT call Rails from the browser, so only Next.js origin is needed.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("CORS_ORIGIN", "http://localhost:3001").split(",").map(&:strip)

    resource "/api/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      credentials: false
  end
end
