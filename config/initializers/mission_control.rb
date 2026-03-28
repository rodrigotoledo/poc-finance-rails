# Dashboard de jobs: http://localhost:3000/jobs
# Credenciais via env — defaults para desenvolvimento local.
# Em produção defina JOBS_DASHBOARD_USER e JOBS_DASHBOARD_PASSWORD no .env / secrets.
Rails.application.configure do
  config.mission_control.jobs.http_basic_auth_credentials = [
    ENV.fetch("JOBS_DASHBOARD_USER",     "admin"),
    ENV.fetch("JOBS_DASHBOARD_PASSWORD", "admin")
  ]
end
