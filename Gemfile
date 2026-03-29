source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.2"
gem "pg", ">= 1.4"
gem "redis", "~> 5.0"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

# API JSON: ?page=&per_page= nas listagens (integração com TanStack Table manualPagination)
gem "pagy", "~> 9.0"

# Soft delete (sets discarded_at; rows stay in the database)
gem "discard", "~> 1.3"

# Money attributes backed by *_cents columns; default currency BRL (see config/initializers/money.rb)
gem "money-rails", "~> 1.15"

# Locale data for Rails (errors, dates, number formats) — add app strings under config/locales/*.yml
gem "rails-i18n", "~> 8.1"

# Web dashboard for Solid Queue (equivalent to Sidekiq Web)
# sprockets-rails is required because mission_control-jobs accesses config.assets,
# which is stripped out in api_only mode.
gem "mission_control-jobs"
gem "sprockets-rails"

# CSV/XLSX import: roo reads both formats; caxlsx generates sample XLSX files
# csv is explicitly required because Ruby 4.0 removed it from default gems
gem "csv", "~> 3.3"
gem "roo", "~> 2.10"
gem "caxlsx", "~> 3.4"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Fake data for seeds / tests
  gem "faker", "~> 3.5"

  # Code coverage report: COVERAGE=true bin/docker-test (output in coverage/)
  gem "simplecov", "~> 0.22", require: false

  # Mocking / stubbing (any_instance for controller destroy else branches)
  gem "mocha", "~> 2.1", require: false
end

group :development do
  # N+1 query detection (see config/environments/development.rb)
  gem "bullet", "~> 8.0"

  # Auto-run Minitest on file save (see compose.yml service `guard`)
  gem "guard", "~> 2.19"
  gem "guard-minitest", "~> 2.4"
end
