class AthleteBlueprint < Blueprinter::Base
  identifier :id
  fields :first_name,
    :last_name,
    :country_code,
    :gender,
    :source,
    :photo_url,
    :flag_url,
    :federation,
    :federation_id,
    :external_athlete_id

  view :extended do
    association :round_results, blueprint: RoundResultBlueprint
  end
end
