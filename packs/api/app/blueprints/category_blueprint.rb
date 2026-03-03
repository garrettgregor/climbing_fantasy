class CategoryBlueprint < Blueprinter::Base
  identifier :id
  fields :name,
    :discipline,
    :gender,
    :external_id

  view :extended do
    association :rounds, blueprint: RoundBlueprint
  end
end
