source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:windows, :jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# JSON serialization
gem "blueprinter"

# HTTP client for IFSC scraping
gem "faraday"

# Headless Chrome fallback for scraping
gem "ferrum"

# Background job processing
gem "sidekiq"
gem "sidekiq-cron"

# Structured query parameters (also used by activeadmin)
gem "ransack"

# Modular architecture enforcement
gem "packwerk", require: false
gem "packs-rails"
gem "benchmark" # required by packwerk (no longer default in Ruby 4)

# Admin dashboard
gem "activeadmin", "~> 4.0.0.beta21"

# Authentication
gem "devise"

# Authorization
gem "pundit"

# Pagination
gem "pagy", "~> 9.0"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: [:mri, :windows], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Shopify Ruby style guide
  gem "rubocop-shopify", require: false
  gem "rubocop-rails",   require: false

  # OpenAPI documentation (serve spec + Swagger UI)
  gem "rswag-api"
  gem "rswag-ui"

  # Validate API responses against OpenAPI spec
  gem "committee"
  gem "committee-rails"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Git hooks manager to catch linting issues before committing
  gem "overcommit", require: false

  # Annotate models, routes, etc. with schema info
  gem "annotaterb"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Test matchers
  gem "shoulda-matchers"
end
