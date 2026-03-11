class CategoryBlueprint < Blueprinter::Base
  identifier :id
  fields :name,
    :discipline,
    :gender,
    :category_status,
    :external_dcat_id

  view :extended do
    association :rounds, blueprint: RoundBlueprint
  end
end
