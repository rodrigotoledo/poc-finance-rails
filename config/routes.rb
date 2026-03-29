Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Solid Queue web dashboard — http://localhost:3000/jobs
  mount MissionControl::Jobs::Engine, at: "/jobs"

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
    end
  end
end
