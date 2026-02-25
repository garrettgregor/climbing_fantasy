class CreateRoundResults < ActiveRecord::Migration[8.1]
  def change
    create_table :round_results do |t|
      t.references :round, null: false, foreign_key: true
      t.references :athlete, null: false, foreign_key: true
      t.integer :rank
      t.string :score_raw

      # Boulder fields
      t.integer :tops
      t.integer :zones
      t.integer :top_attempts
      t.integer :zone_attempts

      # Lead fields
      t.decimal :lead_height
      t.boolean :lead_plus, default: false

      # Speed fields
      t.decimal :speed_time
      t.string :speed_eliminated_stage

      t.timestamps
    end

    add_index :round_results, [ :round_id, :athlete_id ], unique: true
  end
end
