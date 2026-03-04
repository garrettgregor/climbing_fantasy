# Climbing Fantasy

A JSON API serving World Climbing (formerly IFSC) competition
results. Data is synced from the IFSC JSON API at
`ifsc.results.info` via background jobs. The data model is
designed to support a future fantasy league layer.

## Tech Stack

- **Ruby** 4.0.0
- **Rails** 8.1.2
- **PostgreSQL** 17
- **Redis** (Sidekiq backend)
- **Sidekiq** (background jobs)
- **Faraday** (HTTP client for IFSC API)
- **Blueprinter** (JSON serialization)
- **Pagy** (pagination)
- **Devise** (authentication)
- **Pundit** (authorization)
- **ActiveAdmin** (admin dashboard)
- **Minitest** + **shoulda-matchers** (testing)
- **Committee** (OpenAPI schema validation)
- **Tailwind CSS** (styling for future UI)

## Prerequisites

- Ruby 4.0.0 (via rbenv or asdf)
- Node.js (for Tailwind CSS and ActiveAdmin assets)
- PostgreSQL 17
- Redis

### macOS Setup

```bash
brew install postgresql@17 redis node
brew services start postgresql@17
brew services start redis
```

## Getting Started

```bash
# Clone the repo
git clone git@github.com:TopOut-Fantasy/climbing_fantasy.git
cd climbing_fantasy

# Install dependencies
bundle install
npm install

# Create and migrate the database
bin/rails db:create db:migrate

# Seed the admin user
bin/rails db:seed
```

## Running the App

```bash
# Start the Rails server
bin/rails server

# In a separate terminal, start Sidekiq
bundle exec sidekiq
```

Or use the Procfile for both:

```bash
bin/dev
```

## Running Tests

```bash
bin/rails test
```

## API Endpoints

All endpoints are prefixed with `/api/v1`. Responses return
JSON with `data` and `meta` keys.

### Seasons

| Method | Path                  | Description                     |
|--------|-----------------------|---------------------------------|
| GET    | `/api/v1/seasons`     | List all seasons                |
| GET    | `/api/v1/seasons/:id` | Season detail with competitions |

### Competitions

| Method | Path                       | Description                        |
|--------|----------------------------|------------------------------------|
| GET    | `/api/v1/competitions`     | List competitions (filterable)     |
| GET    | `/api/v1/competitions/:id` | Competition detail with categories |

**Filters:** `?season_id=`, `?discipline=`, `?status=`, `?year=`

### Categories

| Method | Path                      | Description                 |
|--------|---------------------------|-----------------------------|
| GET    | `/api/v1/categories/:id`  | Category detail with rounds |

### Rounds

| Method | Path                  | Description                     |
|--------|-----------------------|---------------------------------|
| GET    | `/api/v1/rounds/:id`  | Round detail with results       |

### Athletes

| Method | Path                   | Description                 |
|--------|------------------------|-----------------------------|
| GET    | `/api/v1/athletes`     | List athletes (searchable)  |
| GET    | `/api/v1/athletes/:id` | Athlete detail with results |

**Filters:** `?q=` (name search), `?country=` (country code)

### Pagination

All list endpoints support pagination:

- `?page=1` (default: 1)
- `?per_page=25` (default: 25)

Response includes metadata:

```json
{
  "data": ["..."],
  "meta": { "page": 1, "per_page": 25, "total": 142 }
}
```

## API Documentation

Swagger UI is available at `/api-docs` when the server is
running. The OpenAPI 3.0 spec is at
`swagger/v1/swagger.yaml`.

## Admin Dashboard

ActiveAdmin is available at `/admin`. Log in with the seeded
super_admin account:

- **Email:** `admin@climbingfantasy.com`
- **Password:** `password123456`

### Admin Roles

| Role          | Permissions                                    |
|---------------|------------------------------------------------|
| `super_admin` | Full CRUD on all resources, manage admin users |
| `admin`       | Full CRUD on competition data                  |
| `viewer`      | Read-only access to admin dashboard            |

## Background Jobs

Data sync jobs in `packs/sync` fetch from the IFSC JSON API.
Recurring job schedules will be configured as sync jobs are built.

The Sidekiq Web UI is at `/sidekiq` (super_admin only).

## Data Model

```txt
Season -< Competition -< Category -< Round -< RoundResult >- Athlete
```

- **Season** - A competition year (e.g., "IFSC World Cup 2024")
- **Competition** - A single event (e.g., "Innsbruck 2024")
- **Category** - Discipline + gender (e.g., "Boulder - Men")
- **Round** - Qualification, Semi-Final, or Final
- **RoundResult** - An athlete's score in a round
- **Athlete** - A competitor with name, country, and gender

## Project Structure

```txt
app/
  admin/            # ActiveAdmin resource definitions
  blueprints/       # Blueprinter JSON serializers
  controllers/
    api/v1/         # API controllers
  jobs/             # Sidekiq background jobs
  models/           # ActiveRecord models
  policies/         # Pundit authorization policies
  services/
    ifsc/           # IFSC API client and sync services
config/
  sidekiq.yml       # Sidekiq queue configuration
swagger/
  v1/swagger.yaml   # OpenAPI 3.0 specification
test/
  controllers/      # API request tests
  fixtures/         # YAML fixtures and mock data
  jobs/             # Background job tests
  models/           # Model validation tests
  services/         # Service object tests
```
