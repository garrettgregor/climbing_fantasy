class CategoryBlueprint < Blueprinter::Base
  identifier :id
  fields :name,
    :discipline,
    :gender,
    :external_id,
    :age_category,
    :para_classification,
    :para_intensity

  view :extended do
    association :rounds, blueprint: RoundBlueprint
  end
end
