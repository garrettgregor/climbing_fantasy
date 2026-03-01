# IFSC JSON API Reference

Documentation of the IFSC results JSON API at `https://ifsc.results.info`.

Reference: [sportclimbing/ifsc-calendar](https://github.com/sportclimbing/ifsc-calendar)

## Authentication

The API requires a session cookie obtained from the main site:

1. `GET https://ifsc.results.info/` — grab the `_verticallife_resultservice_session` cookie from the `Set-Cookie` response header
2. Send all API requests with:
   - `Cookie: _verticallife_resultservice_session=<value>`
   - `Referer: https://ifsc.results.info/`

The cookie is a standard Rails session cookie. No login or credentials are needed — just visiting the homepage issues one.

## Base URL

`https://ifsc.results.info/api/v1/...` — requires session cookie + Referer header.

---

## Data Hierarchy

```
Season (e.g. "2024", id=36)
  └─ Leagues (e.g. "World Cups and World Championships")
       └─ season_league (e.g. id=431)
            └─ Events (e.g. "IFSC World Cup Hachioji 2023", id=1291)
                 └─ d_cats (discipline + gender, e.g. "BOULDER Men")
                      └─ category_rounds (e.g. Qualification, Semi-final, Final)
                           └─ results → ranking[] (athlete scores + ascents)
```

---

## Endpoints

### GET /api/v1/seasons/:id

Returns a season with its leagues and all events.

**Known season IDs:** 30 (2017), 31 (2018), 32 (2019), 33 (2021), 34 (2022), 35 (2023), 36 (2024), 37 (2025), 38 (2026)

> Note: There is no `/api/v1/seasons` list endpoint — you must query by ID.

**Response:**

```json
{
  "name": "2026",
  "leagues": [
    {
      "name": "World Cups and World Championships",
      "url": "/api/v1/season_leagues/457"
    },
    {
      "name": "IFSC Youth",
      "url": "/api/v1/season_leagues/458"
    }
    // ... more leagues
  ],
  "events": [
    {
      "event": "World Climbing Oceania Championship Mount Maunganui 2026",
      "event_id": 1491,
      "league_season_id": 467,
      "location": "Mount Maunganui, New Zealand",
      "country": "NZL",
      "url": "/api/v1/events/1491",
      "registration_url": "/api/v1/events/1491/registrations",
      "infosheet_url": "https://ifsc.results.info/events/1491/infosheet",
      "additional_info_url": null,
      "starts_at": "2026-02-13 11:00:00 UTC",
      "ends_at": "2026-02-14 10:59:00 UTC",
      "local_start_date": "2026-02-14",
      "local_end_date": "2026-02-14",
      "timezone": { "value": "Pacific/Auckland" },
      "cup_name": "",
      "cup_id": null,
      "custom_cup_ids": [],
      "registration_deadline": "2026-02-07T23:59:00.000Z",
      "athlete_self_registration": false,
      "event_logo": null,
      "series_logo": null,
      "disciplines": [
        {
          "id": 1826,
          "kind": "speed",
          "event_id": 1491
        }
      ]
    }
    // ... more events
  ]
}
```

---

### GET /api/v1/season_leagues/:id

Returns a league's categories, events, and cups for a specific season.

**Response:**

```json
{
  "season": "2023",
  "league": "World Cups and World Championships",
  "d_cats": [
    { "id": 1, "name": "LEAD Men", "discipline": "Lead", "discipline_kind_id": 0 },
    { "id": 2, "name": "SPEED Men", "discipline": "Speed", "discipline_kind_id": 1 },
    { "id": 3, "name": "BOULDER Men", "discipline": "Boulder", "discipline_kind_id": 2 },
    { "id": 4, "name": "COMBINED Men", "discipline": "Combined", "discipline_kind_id": 3 },
    { "id": 617, "name": "BOULDER&LEAD Men", "discipline": "Boulder&lead", "discipline_kind_id": 4 },
    { "id": 5, "name": "LEAD Women", "discipline": "Lead", "discipline_kind_id": 0 },
    { "id": 6, "name": "SPEED Women", "discipline": "Speed", "discipline_kind_id": 1 },
    { "id": 7, "name": "BOULDER Women", "discipline": "Boulder", "discipline_kind_id": 2 },
    { "id": 8, "name": "COMBINED Women", "discipline": "Combined", "discipline_kind_id": 3 },
    { "id": 618, "name": "BOULDER&LEAD Women", "discipline": "Boulder&lead", "discipline_kind_id": 4 }
  ],
  "events": [ /* same shape as season events */ ],
  "cups": [ /* cup/series standings */ ]
}
```

**Discipline kind IDs:** 0=Lead, 1=Speed, 2=Boulder, 3=Combined, 4=Boulder&Lead

---

### GET /api/v1/events/:id

Returns full event detail including categories and rounds.

**Response:**

```json
{
  "id": 1291,
  "name": "IFSC World Cup Hachioji 2023",
  "type": "classic",
  "league_id": 1,
  "league_season_id": 418,
  "season_id": 35,
  "starts_at": "2023-04-20 15:00:00 UTC",
  "ends_at": "2023-04-23 14:59:00 UTC",
  "local_start_date": "2023-04-21",
  "local_end_date": "2023-04-23",
  "timezone": { "value": "Asia/Tokyo" },
  "location": "Hachioji",
  "country": "JPN",
  "cup_name": "IFSC Climbing World Cup 2023",
  "registration_url": "/api/v1/events/1291/registrations",
  "infosheet_url": "https://ifsc.results.info/events/1291/infosheet",
  "event_logo": "https://d1n1qj9geboqnb.cloudfront.net/ifsc/public/...",
  "series_logo": "https://d1n1qj9geboqnb.cloudfront.net/ifsc/public/...",
  "is_paraclimbing_event": false,
  "rounds": [
    { "id": 2173, "name": "Qualification" },
    { "id": 2284, "name": "Semi-final" },
    { "id": 2285, "name": "Final" }
  ],
  "public_information": {
    "organiser_name": "Hachioji",
    "organiser_url": null,
    "venue_name": null,
    "description": null
  },
  "d_cats": [
    {
      "dcat_id": 3,
      "event_id": 1291,
      "dcat_name": "BOULDER Men",
      "discipline_kind": "boulder",
      "category_id": 5424,
      "category_name": "Men",
      "status": "finished",
      "category_rounds": [
        {
          "category_round_id": 7669,
          "kind": "boulder",
          "name": "Qualification",
          "category": "Men",
          "status": "finished",
          "result_url": "/api/v1/category_rounds/7669/results",
          "starting_groups": [
            {
              "id": 145,
              "name": "Group A",
              "ranking": "/api/v1/starting_groups/145/results",
              "routes": [
                { "id": 8490, "name": "1" },
                { "id": 8491, "name": "2" }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

---

### GET /api/v1/category_rounds/:id/results

Returns full results for a category round, including athlete rankings and per-route ascent data.

**Response shape:**

```json
{
  "id": 7669,
  "event": "IFSC World Cup Hachioji 2023",
  "event_id": 1291,
  "dcat_id": 3,
  "discipline": "Boulder",
  "status": "finished",
  "category": "Men",
  "round": "Qualification",
  "format": "...",
  "starting_groups": [ /* route definitions */ ],
  "ranking": [ /* athlete results — see below */ ],
  "startlist": [ /* start order */ ],
  "next_round_startlist": [ /* athletes advancing */ ]
}
```

#### Boulder ascent shape

```json
{
  "athlete_id": 2276,
  "name": "NARASAKI Tomoa",
  "firstname": "Tomoa",
  "lastname": "NARASAKI",
  "country": "JPN",
  "flag_url": "https://d1n1qj9geboqnb.cloudfront.net/flags/JPN.png",
  "federation_id": 25,
  "bib": "52",
  "rank": 1,
  "score": "5T5z 20 13",
  "start_order": 2,
  "starting_group": "Group B",
  "group_rank": 1,
  "active": false,
  "under_appeal": false,
  "ascents": [
    {
      "route_id": 8495,
      "route_name": "1",
      "top": true,
      "top_tries": 5,
      "zone": true,
      "zone_tries": 3,
      "low_zone": false,
      "low_zone_tries": null,
      "points": 0.0,
      "modified": "2023-04-21 07:38:50 +00:00",
      "status": "confirmed"
    }
  ]
}
```

#### Lead ascent shape

```json
{
  "athlete_id": 1364,
  "name": "Ondra Adam",
  "firstname": "Adam",
  "lastname": "ONDRA",
  "country": "CZE",
  "rank": 1,
  "score": "3.0",
  "ascents": [
    {
      "route_id": 8626,
      "route_name": "1",
      "top": false,
      "plus": false,
      "restarted": false,
      "rank": 1,
      "corrective_rank": 1,
      "score": "41",
      "status": "locked",
      "top_tries": null
    }
  ]
}
```

#### Speed ascent shape

```json
{
  "athlete_id": 3340,
  "name": "LEONARDO VEDDRIQ",
  "firstname": "Veddriq",
  "lastname": "LEONARDO",
  "country": "INA",
  "rank": 1,
  "score": "4.97",
  "score_time": "4.97",
  "record": false,
  "record_types": [],
  "ascents": [
    {
      "route_id": 8631,
      "route_name": "B",
      "time_ms": 4977,
      "dnf": false,
      "dns": false,
      "modified": "2023-07-02 11:34:56 +00:00",
      "status": "locked"
    }
  ]
}
```

---

### GET /api/v1/events/:id/registrations

Returns registered athletes for an event.

**Response:** Array of registration objects.

```json
[
  {
    "athlete_id": 13510,
    "firstname": "Emily",
    "lastname": "SCOTT",
    "name": "SCOTT Emily",
    "gender": 1,
    "federation": "SCA",
    "federation_id": 28,
    "country": "AUS",
    "d_cats": [
      { "id": 7, "name": "BOULDER Women", "status": "confirmed" }
    ]
  }
]
```

**Gender values:** 0 = Male, 1 = Female (inferred)

---

### GET /api/v1/live

Returns currently live events/rounds. Empty array when nothing is live.

```json
{ "live": [] }
```

---

## Field Reference

### Event status values (on d_cats)

- `"not_started"`
- `"active"`
- `"finished"`

### Category round status values

- `"not_started"`
- `"active"` / `"in_progress"`
- `"finished"`

### Discipline kinds

| Kind | discipline_kind_id |
|------|--------------------|
| lead | 0 |
| speed | 1 |
| boulder | 2 |
| combined | 3 |
| boulder&lead | 4 |

### Ascent status values

- `"confirmed"` — boulder
- `"locked"` — lead, speed
