class AthleteBlueprint < Blueprinter::Base
  identifier :id
  fields :first_name,
    :last_name,
    :country_code,
    :gender,
    :external_athlete_id,
    :height,
    :arm_span,
    :birthday

  view :extended do
    association :round_results, blueprint: RoundResultBlueprint
  end
end
