class RenameCompetitionsToEvents < ActiveRecord::Migration[8.1]
  def change
    rename_table :competitions, :events

    rename_column :categories, :competition_id, :event_id
    rename_column :events, :external_event_id, :external_id
    rename_column :categories, :external_category_id, :external_id

    add_column :events, :results_synced_at, :datetime
  end
end
