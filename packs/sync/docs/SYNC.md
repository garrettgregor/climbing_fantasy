# Sync Pack — IFSC Data Pipeline

This document describes how competition data flows from the IFSC results API into the Climbing Fantasy database. Keep this file up to date whenever the sync pack changes.

## Scope

We only sync **World Climbing Series** events (boulder, lead, speed world cups). A single event may be a combined event with multiple disciplines (e.g., both lead and speed categories at the same competition). Para, youth, regional, and continental championship events are excluded. Filtering happens at the SeasonSyncer level by fetching events from the "World Cups and World Championships" league via the season_leagues endpoint, rather than importing all events from a season.

Within each event, EventSyncer only syncs boulder, lead, and speed categories with men's and women's divisions. Combined / boulder&lead categories and non men/women divisions are skipped.

## IFSC API

Base URL: `https://ifsc.results.info/api/v1`

Authentication is a session cookie obtained by visiting the homepage — no credentials required. See `ifsc_json_api.md` in this directory for full endpoint reference.

Key endpoints used by the sync pipeline:

| Endpoint | Used by | Purpose |
|---|---|---|
| `GET /seasons/:id` | SeasonSyncer | Fetch season metadata and league list |
| `GET /season_leagues/:id` | SeasonSyncer | Fetch events scoped to a specific league |
| `GET /events/:id` | EventSyncer | Fetch categories, rounds, and climbs for an event |
| `GET /events/:id/registrations` | RegistrationSyncer | Fetch athlete registrations for an event |
| `GET /category_rounds/:id/results` | ResultSyncer | Fetch results and athlete scores for a round |

## Data model

```
Season
  └─ Event (status + sync_state)
       └─ Category (discipline + gender, keyed by external_dcat_id)
            ├─ Round (round_type + status)
            │    ├─ Climb
            │    └─ RoundResult (per athlete)
            │         └─ ClimbResult (per climb per athlete)
            └─ CategoryRegistration → Athlete
```

## Sync state machine

Each event has two independent enums:

**`status`** — where the event is in time (updated by SeasonSyncer from event dates):
- `upcoming` — event hasn't started yet
- `in_progress` — event is currently happening
- `completed` — event has ended

**`sync_state`** — where the event is in the sync pipeline:
- `pending_sync` — event record exists but categories/rounds have not been fetched
- `needs_results` — categories/rounds are synced, results need to be fetched (or re-fetched)
- `synced` — all data is fully synced

State progression:

```
pending_sync ──[EventSyncer]──> needs_results ──[ResultSyncer]──> synced
```

`sync_state` drives the pipeline. `status` is purely descriptive and does not gate which sync step runs. This means completed (historical) events follow the same pipeline as in-progress events.

## Jobs and schedule

All jobs run on the `sync` queue via sidekiq-cron. Each job rescues `ApiError` per-event and continues processing remaining items.

| Job | Cron | What it does |
|---|---|---|
| `SyncSeasonsJob` | Mon+Thu 6am UTC | 1. Calls SeasonSyncer to discover/update seasons and events. 2. Calls EventSyncer on every `pending_sync` event. |
| `SyncRegistrationsJob` | Daily 7am UTC | Calls RegistrationSyncer for events with `status: upcoming` or `in_progress`. |
| `SyncResultsJob` | Every 4 hours | Calls ResultSyncer for events with `status: in_progress` or `sync_state: needs_results`. Sets `sync_state: synced` when all rounds are completed. |

Rake tasks for manual triggering:

```bash
rake sync:seasons       # runs SyncSeasonsJob inline
rake sync:registrations # runs SyncRegistrationsJob inline
rake sync:results       # runs SyncResultsJob inline
```

## End-to-end flow

### 1. Season + event discovery (SyncSeasonsJob)

**SeasonSyncer** fetches each season in `CURRENT_SEASON_IDS` (currently 37 and 38):
1. Upserts the `Season` record (name, year)
2. Finds the "World Cups and World Championships" league from the season's `leagues[]` array (matches `TARGET_LEAGUE_PATTERN = /world cup/i`)
3. Fetches events from that league via `GET /season_leagues/:id`
4. For each event, upserts an `Event` record with name, location, dates, and time-inferred status
5. New events get `sync_state: pending_sync`

If no matching league is found, a warning is logged and no events are created for that season.

**EventSyncer** then runs on each `pending_sync` event:
1. Fetches `GET /events/:id` for full event detail
2. Filters `d_cats[]` to only boulder, lead, and speed categories with men/women genders
3. Creates/updates `Category` records keyed by `external_dcat_id` (the stable dcat ID from the API)
4. Creates/updates `Round` records from `category_rounds[]` (maps round_type and status)
5. Creates `Climb` records from routes
6. Sets `sync_state: needs_results`

### 2. Registration sync (SyncRegistrationsJob)

**RegistrationSyncer** runs for `upcoming` and `in_progress` events:
1. Fetches `GET /events/:id/registrations`
2. For each registration, finds or creates the `Athlete` record
3. Creates `CategoryRegistration` linking athlete to category (matched by name)
4. Timestamps `registrations_last_checked_at`

### 3. Result sync (SyncResultsJob)

**ResultSyncer** runs for events with `status: in_progress` or `sync_state: needs_results`:
1. Loads all rounds across all categories for the event
2. For each round, fetches `GET /category_rounds/:id/results`
3. Updates round status from the API response
4. For each athlete in the `ranking[]`:
   - Finds or creates the `Athlete` record
   - Upserts `RoundResult` with rank, raw score, and discipline-specific aggregates (speed_time, lead_height)
   - Upserts `ClimbResult` records for each ascent (boulder: top/zone attempts, lead: height/plus, speed: time)
5. Timestamps `results_synced_at`
6. When all rounds for the event are `completed`, sets `sync_state: synced` and `status: completed`

## Services

All services live in `packs/sync/app/services/ifsc/` and follow the same pattern:
- `class << self` with a `call` class method
- Accept a `client:` keyword for testability (defaults to `ApiClient.new`)
- Instance-level `call` method does the work

| Service | Input | Output |
|---|---|---|
| `Ifsc::ApiClient` | — | HTTP wrapper; acquires session cookie on init |
| `Ifsc::SeasonSyncer` | season IDs | Season + Event records |
| `Ifsc::EventSyncer` | event | Category + Round + Climb records |
| `Ifsc::RegistrationSyncer` | event | Athlete + CategoryRegistration records |
| `Ifsc::ResultSyncer` | event | RoundResult + ClimbResult records |

## Known issues / TODO

- **Climb creation**: EventSyncer reads `round_data["routes"]` but boulder qualification routes are nested under `starting_groups[].routes`, so climbs are not created for those rounds.
