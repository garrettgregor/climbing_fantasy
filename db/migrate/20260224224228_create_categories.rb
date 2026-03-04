class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :event, null: false, foreign_key: true
      t.integer :external_dcat_id
      t.string :name, null: false
      t.integer :discipline, null: false
      t.integer :gender, null: false
      t.timestamps
    end
    add_index :categories, [:event_id, :external_dcat_id], unique: true
  end
end
