# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_02_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "athletes", force: :cascade do |t|
    t.integer "active_since_year"
    t.integer "age_last_seen"
    t.date "age_last_seen_at"
    t.float "arm_span"
    t.integer "birth_year_estimate"
    t.string "birth_year_source"
    t.date "birthday"
    t.string "club"
    t.string "country_code", limit: 3, null: false
    t.datetime "created_at", null: false
    t.integer "external_athlete_id"
    t.string "first_name", null: false
    t.integer "gender", null: false
    t.float "height"
    t.string "hometown"
    t.string "last_name", null: false
    t.integer "participations_count"
    t.string "photo_url"
    t.datetime "profile_last_synced_at"
    t.datetime "updated_at", null: false
    t.index ["external_athlete_id"], name: "index_athletes_on_external_athlete_id", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "discipline", null: false
    t.bigint "event_id", null: false
    t.integer "external_dcat_id"
    t.integer "gender", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "external_dcat_id"], name: "index_categories_on_event_id_and_external_dcat_id", unique: true
    t.index ["event_id"], name: "index_categories_on_event_id"
  end

  create_table "category_registrations", force: :cascade do |t|
    t.bigint "athlete_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "registered_at_source"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["athlete_id"], name: "index_category_registrations_on_athlete_id"
    t.index ["category_id", "athlete_id"], name: "index_category_registrations_category_athlete_unique", unique: true
    t.index ["category_id"], name: "index_category_registrations_on_category_id"
  end

  create_table "climb_results", force: :cascade do |t|
    t.bigint "climb_id", null: false
    t.datetime "created_at", null: false
    t.string "disqualification"
    t.decimal "height", precision: 5, scale: 2
    t.integer "high_zone_attempts"
    t.boolean "plus"
    t.integer "rank"
    t.bigint "round_result_id", null: false
    t.string "score_raw"
    t.decimal "time", precision: 7, scale: 3
    t.integer "top_attempts", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "zone_attempts", default: 0, null: false
    t.index ["climb_id"], name: "index_climb_results_on_climb_id"
    t.index ["round_result_id", "climb_id"], name: "index_climb_results_on_round_result_id_and_climb_id", unique: true
    t.index ["round_result_id"], name: "index_climb_results_on_round_result_id"
  end

  create_table "climbs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "group_label"
    t.integer "number", null: false
    t.bigint "round_id", null: false
    t.datetime "updated_at", null: false
    t.index ["round_id", "group_label", "number"], name: "index_climbs_on_round_id_and_group_label_and_number", unique: true
    t.index ["round_id"], name: "index_climbs_on_round_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ends_on", null: false
    t.integer "external_id"
    t.string "info_sheet_url"
    t.string "location", null: false
    t.string "name", null: false
    t.datetime "registrations_last_checked_at"
    t.datetime "results_synced_at"
    t.bigint "season_id", null: false
    t.date "starts_on", null: false
    t.integer "status", default: 0, null: false
    t.integer "sync_state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["season_id"], name: "index_events_on_season_id"
    t.index ["sync_state"], name: "index_events_on_sync_state"
  end

  create_table "round_results", force: :cascade do |t|
    t.bigint "athlete_id", null: false
    t.decimal "boulder_points"
    t.datetime "created_at", null: false
    t.string "group_label"
    t.integer "high_zone_attempts"
    t.integer "high_zones"
    t.decimal "lead_height"
    t.boolean "lead_plus", default: false
    t.integer "rank"
    t.bigint "round_id", null: false
    t.string "score_raw"
    t.string "speed_eliminated_stage"
    t.decimal "speed_time"
    t.integer "top_attempts"
    t.integer "tops"
    t.datetime "updated_at", null: false
    t.integer "zone_attempts"
    t.integer "zones"
    t.index ["athlete_id"], name: "index_round_results_on_athlete_id"
    t.index ["round_id", "athlete_id"], name: "index_round_results_on_round_id_and_athlete_id", unique: true
    t.index ["round_id"], name: "index_round_results_on_round_id"
  end

  create_table "rounds", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.integer "external_round_id"
    t.string "name", null: false
    t.string "round_type", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_rounds_on_category_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "external_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "year"
  end

  add_foreign_key "categories", "events"
  add_foreign_key "category_registrations", "athletes"
  add_foreign_key "category_registrations", "categories"
  add_foreign_key "climb_results", "climbs"
  add_foreign_key "climb_results", "round_results"
  add_foreign_key "climbs", "rounds"
  add_foreign_key "events", "seasons"
  add_foreign_key "round_results", "athletes"
  add_foreign_key "round_results", "rounds"
  add_foreign_key "rounds", "categories"
end
