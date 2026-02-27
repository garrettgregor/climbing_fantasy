class CreateClimbsAndClimbResults < ActiveRecord::Migration[8.1]
  def change
    create_table :climbs do |t|
      t.references :round, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :group_label

      t.timestamps
    end

    add_index :climbs, [ :round_id, :group_label, :number ], unique: true

    create_table :climb_results do |t|
      t.references :round_result, null: false, foreign_key: true
      t.references :climb, null: false, foreign_key: true
      t.string :score_raw
      t.integer :rank
      t.integer :top_attempts, default: 0, null: false
      t.integer :zone_attempts, default: 0, null: false
      t.decimal :height, precision: 5, scale: 2
      t.boolean :plus
      t.decimal :time, precision: 7, scale: 3
      t.string :disqualification

      t.timestamps
    end

    add_index :climb_results, [ :round_result_id, :climb_id ], unique: true
  end
end
