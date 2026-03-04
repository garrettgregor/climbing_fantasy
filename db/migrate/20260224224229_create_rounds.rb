class CreateRounds < ActiveRecord::Migration[8.1]
  def change
    create_table :rounds do |t|
      t.references :category, null: false, foreign_key: true
      t.integer :external_round_id
      t.string :name, null: false
      t.string :round_type, null: false
      t.integer :status, default: 0, null: false
      t.timestamps
    end
  end
end
