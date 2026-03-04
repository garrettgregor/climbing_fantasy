#!/usr/bin/env ruby

require "active_support/core_ext/enumerable"
require "date"
require "erb"
require "fileutils"
require "json"
require "yaml"

ROOT = File.expand_path("../..", __dir__)
FIXTURE_DIR = File.join(ROOT, "test/fixtures")
OUT_COLLECTION = File.join(ROOT, "postman/collections/climbing_fantasy_api.postman_collection.json")
OUT_LOCAL_ENV = File.join(ROOT, "postman/environments/climbing_fantasy_local.postman_environment.json")
OUT_MOCK_ENV = File.join(ROOT, "postman/environments/climbing_fantasy_mock.postman_environment.json")

EVENT_STATUSES = {
  0 => "upcoming",
  1 => "in_progress",
  2 => "completed",
}.freeze
CATEGORY_DISCIPLINES = {
  0 => "boulder",
  1 => "lead",
  2 => "speed",
  3 => "combined",
  4 => "boulder_and_lead",
}.freeze
CATEGORY_GENDERS = {
  0 => "male",
  1 => "female",
  2 => "non_binary",
  3 => "other",
  4 => "mixed",
}.freeze
ROUND_STATUSES = {
  0 => "pending",
  1 => "in_progress",
  2 => "completed",
}.freeze
ATHLETE_GENDERS = {
  0 => "male",
  1 => "female",
  2 => "non_binary",
  3 => "other",
}.freeze

def load_fixture(filename)
  raw = YAML.safe_load(
    ERB.new(File.read(File.join(FIXTURE_DIR, filename))).result,
    permitted_classes: [Date, Time],
    aliases: true,
  ) || {}

  raw.reject { |key, _| key.start_with?("#") || key.include?("Schema") }
end

def with_ids(data)
  data.each_with_index.to_h do |(label, attrs), idx|
    [label, attrs.merge("__id" => idx + 1)]
  end
end

def response(code:, request:, name:, body:)
  {
    "name" => name,
    "originalRequest" => request,
    "status" => (code == 200 ? "OK" : "Not Found"),
    "code" => code,
    "_postman_previewlanguage" => "json",
    "header" => [
      { "key" => "Content-Type", "value" => "application/json" },
    ],
    "body" => JSON.pretty_generate(body),
  }
end

def request_item(name:, url:, success_body:, not_found_body: nil)
  request = {
    "method" => "GET",
    "header" => [],
    "url" => url,
  }

  responses = [
    response(code: 200, request:, name: "200 OK", body: success_body),
  ]

  if not_found_body
    responses << response(code: 404, request:, name: "404 Not Found", body: not_found_body)
  end

  {
    "name" => name,
    "request" => request,
    "response" => responses,
  }
end

seasons_data = with_ids(load_fixture("seasons.yml"))
events_data = with_ids(load_fixture("events.yml"))
categories_data = with_ids(load_fixture("categories.yml"))
rounds_data = with_ids(load_fixture("rounds.yml"))
athletes_data = with_ids(load_fixture("athletes.yml"))
round_results_data = with_ids(load_fixture("round_results.yml"))

seasons = seasons_data.map do |_label, attrs|
  {
    id: attrs.fetch("__id"),
    name: attrs.fetch("name"),
    year: attrs.fetch("year"),
    external_id: attrs.fetch("external_id"),
  }
end
season_id_by_label = seasons_data.transform_values { |attrs| attrs.fetch("__id") }
season_by_id = seasons.index_by { |x| x[:id] }

events = events_data.map do |_label, attrs|
  {
    id: attrs.fetch("__id"),
    name: attrs.fetch("name"),
    location: attrs.fetch("location"),
    starts_on: attrs.fetch("starts_on"),
    ends_on: attrs.fetch("ends_on"),
    status: EVENT_STATUSES.fetch(attrs.fetch("status")),
    season_id: season_id_by_label.fetch(attrs.fetch("season")),
    external_id: attrs.fetch("external_id"),
    results_synced_at: nil,
  }
end
event_id_by_label = events_data.transform_values { |attrs| attrs.fetch("__id") }

categories = categories_data.map do |_label, attrs|
  {
    id: attrs.fetch("__id"),
    name: attrs.fetch("name"),
    discipline: CATEGORY_DISCIPLINES.fetch(attrs.fetch("discipline")),
    gender: CATEGORY_GENDERS.fetch(attrs.fetch("gender")),
    external_dcat_id: attrs.fetch("external_dcat_id"),
    event_id: event_id_by_label.fetch(attrs.fetch("event")),
  }
end
category_id_by_label = categories_data.transform_values { |attrs| attrs.fetch("__id") }

rounds = rounds_data.map do |_label, attrs|
  {
    id: attrs.fetch("__id"),
    name: attrs.fetch("name"),
    round_type: attrs.fetch("round_type"),
    status: ROUND_STATUSES.fetch(attrs.fetch("status")),
    external_round_id: attrs.fetch("external_round_id"),
    category_id: category_id_by_label.fetch(attrs.fetch("category")),
  }
end
round_id_by_label = rounds_data.transform_values { |attrs| attrs.fetch("__id") }

athletes = athletes_data.map do |_label, attrs|
  {
    id: attrs.fetch("__id"),
    first_name: attrs.fetch("first_name"),
    last_name: attrs.fetch("last_name"),
    country_code: attrs.fetch("country_code"),
    gender: ATHLETE_GENDERS.fetch(attrs.fetch("gender")),
    external_athlete_id: attrs.fetch("external_athlete_id"),
  }
end
athlete_id_by_label = athletes_data.transform_values { |attrs| attrs.fetch("__id") }
athlete_by_id = athletes.index_by { |x| x[:id] }

round_results = round_results_data.map do |_label, attrs|
  {
    id: attrs.fetch("__id"),
    rank: attrs["rank"],
    score_raw: attrs["score_raw"],
    group_label: attrs["group_label"],
    tops: attrs["tops"],
    zones: attrs["zones"],
    top_attempts: attrs["top_attempts"],
    zone_attempts: attrs["zone_attempts"],
    lead_height: attrs["lead_height"],
    lead_plus: attrs["lead_plus"] || false,
    speed_time: attrs["speed_time"],
    speed_eliminated_stage: attrs["speed_eliminated_stage"],
    round_id: round_id_by_label.fetch(attrs.fetch("round")),
    athlete_id: athlete_id_by_label.fetch(attrs.fetch("athlete")),
  }
end

sorted_athletes = athletes.sort_by { |a| [a[:last_name], a[:first_name]] }

season_sample = seasons.find { |s| s[:external_id] == 37 } || seasons.first
event_sample = events.find { |e| e[:season_id] == season_sample[:id] } || events.first
category_sample = categories.find { |c| c[:event_id] == event_sample[:id] } || categories.first
round_sample = rounds.find { |r| r[:category_id] == category_sample[:id] } || rounds.first
athlete_sample = sorted_athletes.find { |a| a[:country_code] == "USA" } || sorted_athletes.first

seasons_index = { data: seasons, meta: { page: 1, per_page: 25, total: seasons.size } }
season_show = {
  data: season_sample.merge(events: events.select { |e| e[:season_id] == season_sample[:id] }),
}
events_index = { data: events, meta: { page: 1, per_page: 25, total: events.size } }
event_show = {
  data: event_sample.merge(
    season: season_by_id.fetch(event_sample[:season_id]),
    categories: categories.select { |c| c[:event_id] == event_sample[:id] },
  ),
}
category_show = {
  data: category_sample.merge(rounds: rounds.select { |r| r[:category_id] == category_sample[:id] }),
}
round_show = {
  data: round_sample.merge(
    round_results: round_results
      .select { |rr| rr[:round_id] == round_sample[:id] }
      .map { |rr| rr.merge(athlete: athlete_by_id.fetch(rr[:athlete_id])) },
  ),
}
athletes_index = {
  data: sorted_athletes.first(25),
  meta: { page: 1, per_page: 25, total: sorted_athletes.size },
}
athlete_show = {
  data: athlete_sample.merge(
    round_results: round_results.select { |rr| rr[:athlete_id] == athlete_sample[:id] },
  ),
}

not_found = { error: "Not found" }

collection = {
  "info" => {
    "name" => "Climbing Fantasy API",
    "description" => "Generated from OpenAPI + fixture-backed examples for realistic mocks.",
    "schema" => "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
  },
  "variable" => [
    { "key" => "baseUrl", "value" => "http://localhost:3000" },
    { "key" => "seasonId", "value" => season_sample[:id].to_s },
    { "key" => "eventId", "value" => event_sample[:id].to_s },
    { "key" => "categoryId", "value" => category_sample[:id].to_s },
    { "key" => "roundId", "value" => round_sample[:id].to_s },
    { "key" => "athleteId", "value" => athlete_sample[:id].to_s },
    { "key" => "athleteQuery", "value" => athlete_sample[:last_name] },
    { "key" => "countryCode", "value" => athlete_sample[:country_code] },
    { "key" => "year", "value" => season_sample[:year].to_s },
    { "key" => "discipline", "value" => category_sample[:discipline] },
    { "key" => "eventStatus", "value" => event_sample[:status] },
  ],
  "item" => [
    {
      "name" => "Seasons",
      "item" => [
        request_item(
          name: "List seasons",
          url: "{{baseUrl}}/api/v1/seasons?page=1&per_page=25",
          success_body: seasons_index,
        ),
        request_item(
          name: "Get season",
          url: "{{baseUrl}}/api/v1/seasons/{{seasonId}}",
          success_body: season_show,
          not_found_body: not_found,
        ),
      ],
    },
    {
      "name" => "Events",
      "item" => [
        request_item(
          name: "List events",
          url: "{{baseUrl}}/api/v1/events?season_id={{seasonId}}&discipline={{discipline}}&status={{eventStatus}}&year={{year}}&page=1&per_page=25",
          success_body: events_index,
        ),
        request_item(
          name: "Get event",
          url: "{{baseUrl}}/api/v1/events/{{eventId}}",
          success_body: event_show,
          not_found_body: not_found,
        ),
      ],
    },
    {
      "name" => "Categories",
      "item" => [
        request_item(
          name: "Get category",
          url: "{{baseUrl}}/api/v1/categories/{{categoryId}}",
          success_body: category_show,
          not_found_body: not_found,
        ),
      ],
    },
    {
      "name" => "Rounds",
      "item" => [
        request_item(
          name: "Get round",
          url: "{{baseUrl}}/api/v1/rounds/{{roundId}}",
          success_body: round_show,
          not_found_body: not_found,
        ),
      ],
    },
    {
      "name" => "Athletes",
      "item" => [
        request_item(
          name: "List athletes",
          url: "{{baseUrl}}/api/v1/athletes?q={{athleteQuery}}&country={{countryCode}}&page=1&per_page=25",
          success_body: athletes_index,
        ),
        request_item(
          name: "Get athlete",
          url: "{{baseUrl}}/api/v1/athletes/{{athleteId}}",
          success_body: athlete_show,
          not_found_body: not_found,
        ),
      ],
    },
  ],
}

local_env = {
  "name" => "Climbing Fantasy Local",
  "values" => [
    { "key" => "baseUrl", "value" => "http://localhost:3000", "type" => "default", "enabled" => true },
    { "key" => "seasonId", "value" => season_sample[:id].to_s, "type" => "default", "enabled" => true },
    { "key" => "eventId", "value" => event_sample[:id].to_s, "type" => "default", "enabled" => true },
    { "key" => "categoryId", "value" => category_sample[:id].to_s, "type" => "default", "enabled" => true },
    { "key" => "roundId", "value" => round_sample[:id].to_s, "type" => "default", "enabled" => true },
    { "key" => "athleteId", "value" => athlete_sample[:id].to_s, "type" => "default", "enabled" => true },
    { "key" => "athleteQuery", "value" => athlete_sample[:last_name], "type" => "default", "enabled" => true },
    { "key" => "countryCode", "value" => athlete_sample[:country_code], "type" => "default", "enabled" => true },
    { "key" => "year", "value" => season_sample[:year].to_s, "type" => "default", "enabled" => true },
    { "key" => "discipline", "value" => category_sample[:discipline], "type" => "default", "enabled" => true },
    { "key" => "eventStatus", "value" => event_sample[:status], "type" => "default", "enabled" => true },
  ],
  "_postman_variable_scope" => "environment",
  "_postman_exported_at" => Time.now.utc.iso8601,
  "_postman_exported_using" => "scripts/postman/build_postman_assets.rb",
}

mock_env = local_env.dup
mock_env["name"] = "Climbing Fantasy Mock"
mock_env["values"] = local_env.fetch("values").map do |val|
  if val.fetch("key") == "baseUrl"
    val.merge("value" => "https://replace-me.mock.pstmn.io")
  else
    val
  end
end

FileUtils.mkdir_p(File.dirname(OUT_COLLECTION))
FileUtils.mkdir_p(File.dirname(OUT_LOCAL_ENV))
FileUtils.mkdir_p(File.dirname(OUT_MOCK_ENV))

File.write(OUT_COLLECTION, JSON.pretty_generate(collection))
File.write(OUT_LOCAL_ENV, JSON.pretty_generate(local_env))
File.write(OUT_MOCK_ENV, JSON.pretty_generate(mock_env))

puts "Wrote #{OUT_COLLECTION}"
puts "Wrote #{OUT_LOCAL_ENV}"
puts "Wrote #{OUT_MOCK_ENV}"
