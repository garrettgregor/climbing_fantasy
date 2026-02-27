ActiveAdmin.register(RoundResult) do
  menu priority: 7

  permit_params :round_id,
    :athlete_id,
    :rank,
    :score_raw,
    :tops,
    :zones,
    :top_attempts,
    :zone_attempts,
    :lead_height,
    :lead_plus,
    :speed_time,
    :speed_eliminated_stage

  index do
    selectable_column
    id_column
    column("Athlete") { |r| link_to "#{r.athlete.first_name} #{r.athlete.last_name}", admin_athlete_path(r.athlete) }
    column(:round) { |r| link_to r.round.name, admin_round_path(r.round) }
    column :rank
    column :score_raw
    actions
  end

  filter :athlete
  filter :round
  filter :rank
end
