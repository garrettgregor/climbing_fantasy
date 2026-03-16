# Agents

Guidance for AI coding agents working with the Climbing Fantasy codebase.
Shared durable agent state lives in:

- `.agents/README.md`
- `.agents/lessons.md`

## Workflow Orchestration

### 1. Plan Mode Default

- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately – don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy

- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop

- After ANY correction from the user: update `.agents/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done

- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes – don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing

- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests – then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Agent State

1. **Shared State Lives in `.agents/`**: Put cross-agent guidance and durable notes in `.agents/`.
2. **Lessons Are Shared**: Update `.agents/lessons.md` after corrections so Claude, Codex, and future agents read the same history.
3. **Tasks Are Ephemeral**: Do not create persistent task-tracking files in the repo. Keep plans in your tool state or working context unless the user explicitly asks for a checked-in task document.
4. **Keep Shared Files Focused**: `.agents/` should contain durable agent guidance, not per-task scratch notes.

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

## Development setup

Prerequisites: Ruby 4.0.0, Node.js, PostgreSQL 17, Redis.

```bash
bin/setup           # interactive: bundle, db:prepare, optional db:reset, starts dev server
bin/dev             # start Rails server + Tailwind watchers via Procfile.dev
```

The app runs on `localhost:3000`. Admin dashboard at `/admin`, Swagger UI at `/api-docs`.

### Admin login (seeded)

- Email: `admin@climbingfantasy.com`
- Password: `password123456`

## Testing & CI

Run the full test suite:

```bash
bin/rails test                  # unit, model, controller, service, job tests
bin/rails test:system           # system tests (Capybara + Selenium)
```

CI pipeline (GitHub Actions, `.github/workflows/ci.yml`) runs five jobs:

1. **scan_ruby** — Brakeman security scan + Bundler-Audit
2. **scan_js** — Importmap audit
3. **lint** — RuboCop (Shopify style guide)
4. **test** — Minitest with PostgreSQL service
5. **system-test** — Capybara system tests, uploads screenshots on failure

Run linting and security scans locally:

```bash
bin/rubocop                     # RuboCop (rubocop-shopify + rubocop-rails)
bundle exec packwerk check      # Packwerk architectural boundary check
bin/brakeman                    # Rails security scanner
bin/bundler-audit               # Gem vulnerability audit
```

Pre-commit hooks via Overcommit (`.overcommit.yml`) run RuboCop, Packwerk, BundleAudit, and Brakeman automatically.

## Postman Sync

Keep Postman assets in sync with the API whenever endpoints or `swagger/v1/swagger.yaml` change.

1. Export your Postman API key in shell:
   `export POSTMAN_API_KEY='PMAK-...'`
2. Build fixture-backed Postman assets:
   `ruby scripts/postman/build_postman_assets.rb`
3. Sync collection, environments, and mock server to the team workspace:
   `bash scripts/postman/sync_postman_resources.sh`

Notes:

- The generated Postman examples are derived from `test/fixtures/*.yml` so mocks stay realistic.
- If fixture-backed API examples change in `test/fixtures/*.yml`, keep corresponding examples in `swagger/v1/swagger.yaml` consistent before regenerating Postman assets.
- Default workspace name is `Team Workspace`; override with `POSTMAN_WORKSPACE_NAME`.
- Never commit raw API keys.

## Architecture

### Data model

```txt
Season -< Competition -< Category -< Round -< RoundResult >- Athlete
```

- **Season** — competition year (e.g., "IFSC World Cup 2024")
- **Event** — single competition event with status enum (upcoming, in_progress, completed) and sync_state enum (pending_sync, synced, needs_results). Discipline lives on Category, not Event.
- **Category** — discipline + gender combination
- **Round** — qualification, semi_final, or final with status tracking
- **RoundResult** — athlete's score in a round (tops, zones, attempts, lead height, speed time)
- **Athlete** — competitor with name, country_code (3 chars), gender, physical stats
- **AdminUser** — Devise-authenticated with roles: viewer, admin, super_admin

### API (read-only, JSON)

All endpoints are namespaced under `api/v1`. Controllers inherit from `Api::V1::BaseController` which extends `ActionController::API` and includes Pagy pagination.

```txt
GET /api/v1/seasons             # paginated list
GET /api/v1/seasons/:id         # includes competitions
GET /api/v1/events              # filterable: season_id, discipline (via categories), status, year
GET /api/v1/events/:id          # includes season + categories
GET /api/v1/categories/:id      # includes rounds
GET /api/v1/rounds/:id          # includes results + athletes (eager loaded)
GET /api/v1/athletes            # searchable: q (name), country
GET /api/v1/athletes/:id        # includes results
```

Response shape: `{ "data": [...], "meta": { "page": 1, "per_page": 25, "total": N } }`

### Serialization

Blueprinter serializers live in `packs/api/app/blueprints/`. Each has a default view and an extended view that includes associations.

### Authorization

Pundit policies in `packs/admin/app/policies/` gate admin access by role. API endpoints are public (no auth required).

### OpenAPI validation

Tests use Committee to validate API responses against `swagger/v1/swagger.yaml`. The test helper loads the spec and provides `assert_schema_conform` for controller tests.

## Data syncing

Data flows in from the IFSC results API via background jobs. No manual data entry through the API — it is read-only.

### IFSC services (`packs/sync/app/services/ifsc/`)

- **Ifsc::ApiClient** — Faraday HTTP wrapper around `ifsc.results.info`. Acquires session cookie on init. Raises `Ifsc::ApiClient::ApiError` on failures.
- **Ifsc::SeasonSyncer** — fetches seasons by ID, upserts Season + Event records. Infers event status from dates. New events get `sync_state: :pending_sync`.
- **Ifsc::EventSyncer** — fetches event detail, upserts Category, Round, and Climb records from `d_cats[]`. Maps discipline, gender, round_type. Marks event `sync_state: :synced`.
- **Ifsc::RegistrationSyncer** — fetches event registrations, find-or-creates Athletes and CategoryRegistrations. Matches categories by name.
- **Ifsc::ResultSyncer** — iterates event rounds, fetches results per round, upserts RoundResult + ClimbResult. Aggregates speed times and scores. Finalizes event status when all rounds complete.

All services use `class << self` with a `call` interface and accept `client:` keyword for testability.

### Background jobs

Sidekiq + sidekiq-cron. Queues: `default`, `sync`.

| Job                    | Schedule                       | Description                                          |
|------------------------|--------------------------------|------------------------------------------------------|
| `SyncSeasonsJob`       | Mon+Thu 6am UTC (`0 6 * * 1,4`) | Discover seasons/events, sync pending event details  |
| `SyncRegistrationsJob` | Daily 7am UTC (`0 7 * * *`)     | Sync registrations for upcoming/active events        |
| `SyncResultsJob`       | Every 4 hours (`0 */4 * * *`)   | Poll results for active events (no-op when none)     |

Each job rescues `ApiError` per-event and continues processing remaining items.

Sidekiq Web UI at `/sidekiq` (super_admin only).

## Project structure

```txt
app/                          # Base classes only (root package)
  controllers/
    application_controller.rb
  jobs/
    application_job.rb
  models/
    admin_user.rb
    application_record.rb
packs/
  core/                       # Domain models — no inbound pack dependencies
    app/models/               # Event, Season, Category, Round, RoundResult, Athlete, Climb, ClimbResult
  api/                        # JSON API layer — depends on core
    app/blueprints/           # Blueprinter serializers
    app/controllers/api/v1/   # BaseController + 5 resource controllers
    app/queries/              # EventQuery, AthleteQuery (ransack-backed)
  admin/                      # Admin interface — depends on core
    app/admin/                # ActiveAdmin resource definitions
    app/policies/             # Pundit authorization policies
  sync/                       # Data sync — depends on core
    app/jobs/                 # Sidekiq background jobs
    app/services/ifsc/        # IFSC API client and data syncers
    lib/tasks/sync.rake       # Rake tasks for backfill/sync
config/
  database.yml        # PostgreSQL, multi-db in production (primary, cache, queue, cable)
  sidekiq.yml         # Queue configuration
  deploy.yml          # Kamal deployment config
  routes.rb           # API routes, ActiveAdmin, Sidekiq Web, Swagger
swagger/
  v1/swagger.yaml     # OpenAPI 3.0 specification
test/
  controllers/        # API request tests
  fixtures/           # YAML fixtures and mock data
  jobs/               # Background job tests
  models/             # Model validation tests
  queries/            # Query object tests
  services/           # Service object tests
packwerk.yml          # Packwerk configuration (include_paths: app, packs/*/app)
```

## Conventions

- **Ruby style:** Shopify style guide via `rubocop-shopify` + `rubocop-rails`. No frozen_string_literal magic comments (Ruby 4 default). `class << self` for class methods.
- **Architecture:** Packwerk packages in `packs/`. Run `bundle exec packwerk check` to validate boundaries. `packs/core` has no inbound pack deps; api/admin/sync depend only on core.
- **Filtering:** API filtering goes through query objects (`packs/api/app/queries/`). Use Ransack predicates — pass enum integer values (e.g., `Event.statuses[status_string]`) not strings.
- **Testing:** Minitest with parallel workers. Shoulda-matchers for model validations. Committee for API schema conformance. Query tests in `test/queries/`.
- **Models:** Enums for discipline, status, gender, round_type, role. Each model declares explicit `ransackable_attributes`/`ransackable_associations` allowlists.
- **Services:** Class method interfaces via `class << self`. IFSC services take a client in the initializer for testability.
- **Controllers:** Thin controllers — delegate filtering to query objects, pagination via Pagy.
- **Serialization:** Blueprinter with default and extended views. No inline JSON rendering.
- **Jobs:** Rescue from `ApiError`, log, and continue processing remaining items.
- **Database:** PostgreSQL with UUID-less integer primary keys. Multi-database in production (Solid Cache, Solid Queue, Solid Cable).
- **Migrations:** One migration per table. Split changes to different tables into separate migration files so each migration has a single concern.
- **Enum scopes:** Prefer enum scopes (`Event.needs_results`, `Event.in_progress`) over `.where(sync_state: :needs_results)`.
- **Sync pack docs:** When changing `packs/sync/`, update `packs/sync/docs/SYNC.md` to reflect the new behavior.

## Commit workflow (Conventional Commits)

Use small, single-purpose commits and follow Conventional Commits:

- Commit format: `<type>(<scope>): <summary>`
- Common types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`
- Scope should name the subsystem (examples: `sync`, `fixtures`, `seeds`, `api`, `ci`)
- Keep each commit focused to one logical change (for example: service deletion, fixture rewrite, seed behavior, CI workflow)
- Stage explicitly by file (`git add <paths>`) to avoid mixing concerns
- Run relevant checks before committing (`bin/rubocop`, `bundle exec packwerk check`, and targeted tests for touched areas)
- When `swagger/v1/swagger.yaml`, `test/fixtures/*.yml`, or `scripts/postman/build_postman_assets.rb` change, rebuild Postman assets (`ruby scripts/postman/build_postman_assets.rb`) and include the generated files in the commit

## Deployment

Docker multi-stage build with Kamal orchestration. Production uses Thruster for HTTP acceleration in front of Puma. Config in `config/deploy.yml` and `.kamal/secrets`.

```bash
bin/kamal deploy            # deploy to production
bin/kamal console           # Rails console on server
bin/kamal logs              # tail production logs
```
