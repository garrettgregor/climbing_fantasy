class AddHtmlSyncFieldsToEvents < ActiveRecord::Migration[8.1]
  def change
    change_table(:events, bulk: true) do |t|
      t.integer(:sync_state, null: false, default: 0)
      t.datetime(:registrations_last_checked_at)
      t.string(:info_sheet_url)
    end

    add_index(:events, :sync_state)
  end
end
