class RemoveParaAgeColumnsFromCategories < ActiveRecord::Migration[8.1]
  def change
    remove_column :categories, :age_category, :string, default: "Open", null: false
    remove_column :categories, :para_classification, :string
    remove_column :categories, :para_intensity, :integer
  end
end
