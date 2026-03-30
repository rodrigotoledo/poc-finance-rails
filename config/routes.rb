Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Solid Queue web dashboard — http://localhost:3000/jobs
  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Letter Opener Web — http://localhost:3000/letter_opener
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Sidekiq Web UI — http://localhost:3000/sidekiq (Basic Auth via env)
  require "sidekiq/web"
  Sidekiq::Web.use Rack::Auth::Basic do |user, pass|
    expected_user = ENV.fetch("SIDEKIQ_WEB_USER", "admin")
    expected_pass = ENV.fetch("SIDEKIQ_WEB_PASSWORD", "admin")
    ActiveSupport::SecurityUtils.secure_compare(user.to_s, expected_user) &
      ActiveSupport::SecurityUtils.secure_compare(pass.to_s, expected_pass)
  end
  mount Sidekiq::Web => "/sidekiq"

  # OpenAPI docs (Swagger UI) — http://localhost:3000/api-docs/
  # Served as static files from public/api-docs/

  namespace :api do
    namespace :v1 do
      resources :originators
      resources :receivables
      resources :credit_operations
      resources :regulatory_gaps
      resources :imports, only: %i[index show create]
    end

    namespace :v2 do
      # Dashboard — stats + SSE stream (padrão OpenAPI 3.1)
      get  "dashboard", to: "dashboard#stats"
      get  "events",    to: "dashboard#events"

      resources :originators
      resources :receivables
      resources :credit_operations
      resources :regulatory_gaps
      resources :imports, only: %i[index show create]
      resources :exports, only: %i[create show]
    end
  end
end
