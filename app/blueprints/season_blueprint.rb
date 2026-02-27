class SeasonBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :year, :external_id

  view :extended do
    association :events, blueprint: EventBlueprint
  end
end
