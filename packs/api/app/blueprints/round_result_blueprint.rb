class RoundResultBlueprint < Blueprinter::Base
  identifier :id
  fields :rank,
    :score_raw,
    :group_label,
    :tops,
    :zones,
    :top_attempts,
    :zone_attempts,
    :lead_height,
    :lead_plus,
    :speed_time,
    :speed_eliminated_stage

  view :with_athlete do
    association :athlete, blueprint: AthleteBlueprint
  end
end
