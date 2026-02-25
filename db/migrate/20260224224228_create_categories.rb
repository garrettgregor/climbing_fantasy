class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :competition, null: false, foreign_key: true
      t.integer :external_category_id
      t.string :name, null: false
      t.integer :discipline, null: false
      t.integer :gender, null: false

      t.timestamps
    end

    add_index :categories, [ :competition_id, :external_category_id ], unique: true
  end
end
