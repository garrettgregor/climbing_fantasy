class EventBlueprint < Blueprinter::Base
  identifier :id
  fields :name,
    :location,
    :country_code,
    :starts_on,
    :ends_on,
    :starts_at,
    :ends_at,
    :timezone_name,
    :status,
    :source,
    :season_id,
    :external_id,
    :results_synced_at

  view :extended do
    association :season, blueprint: SeasonBlueprint
    association :categories, blueprint: CategoryBlueprint
  end
end
