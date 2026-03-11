class RoundResultBlueprint < Blueprinter::Base
  identifier :id
  fields :rank,
    :score_raw,
    :group_label,
    :start_order,
    :bib,
    :starting_group,
    :group_rank,
    :active,
    :under_appeal,
    :tops,
    :zones,
    :top_attempts,
    :zone_attempts,
    :boulder_points,
    :high_zones,
    :high_zone_attempts,
    :lead_height,
    :lead_plus,
    :speed_time,
    :speed_eliminated_stage

  view :with_athlete do
    association :athlete, blueprint: AthleteBlueprint
  end
end
