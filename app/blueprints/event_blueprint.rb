class EventBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :location, :starts_on, :ends_on, :discipline, :status,
         :season_id, :external_id, :results_synced_at

  view :extended do
    association :season, blueprint: SeasonBlueprint
    association :categories, blueprint: CategoryBlueprint
  end
end
