class AddHtmlSyncFieldsToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :sync_state, :integer, null: false, default: 0
    add_column :events, :registrations_last_checked_at, :datetime
    add_column :events, :results_last_synced_at, :datetime
    add_column :events, :info_sheet_url, :string

    add_index :events, :sync_state
  end
end
