class RemoveDisciplineFromEvents < ActiveRecord::Migration[8.1]
  def change
    remove_column :events, :discipline, :integer, null: false
  end
end
