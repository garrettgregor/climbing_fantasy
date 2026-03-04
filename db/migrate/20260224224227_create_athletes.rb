class CreateAthletes < ActiveRecord::Migration[8.1]
  def change
    create_table :athletes do |t|
      t.integer :external_athlete_id
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :country_code, limit: 3, null: false
      t.integer :gender, null: false
      t.string :photo_url
      t.timestamps
    end
    add_index :athletes, :external_athlete_id, unique: true
  end
end
