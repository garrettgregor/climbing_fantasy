class RoundBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :round_type, :status, :external_round_id

  view :extended do
    association :round_results, blueprint: RoundResultBlueprint, view: :with_athlete
  end
end
