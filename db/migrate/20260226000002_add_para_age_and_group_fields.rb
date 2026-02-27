class AddParaAgeAndGroupFields < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :para_classification, :string
    add_column :categories, :para_intensity, :integer
    add_column :categories, :age_category, :string, default: "Open", null: false

    add_column :round_results, :group_label, :string

    # Expand round_type from integer enum to string enum
    # Old values: 0=qualification, 1=semi_final, 2=final
    # New values: string-based with additional types
    change_column :rounds, :round_type, :string, null: false, using: <<~SQL
      CASE round_type
        WHEN 0 THEN 'qualification'
        WHEN 1 THEN 'semi_final'
        WHEN 2 THEN 'final'
        ELSE 'qualification'
      END
    SQL
  end
end
