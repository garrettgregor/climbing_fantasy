ActiveAdmin.register(Round) do
  menu priority: 6

  permit_params :category_id,
    :external_round_id,
    :name,
    :round_type,
    :status

  scope :all
  scope :pending
  scope :in_progress
  scope :completed

  index do
    selectable_column
    id_column
    column :name
    column :round_type
    column :status
    column(:category) { |r| link_to r.category.name, admin_category_path(r.category) }
    column("Results") { |r| r.round_results.count }
    actions
  end

  filter :category
  filter :name
  filter :round_type, as: :select, collection: Round.round_types
  filter :status, as: :select, collection: Round.statuses

  show do
    attributes_table do
      row :name
      row :round_type
      row :status
      row(:category) { |r| link_to r.category.name, admin_category_path(r.category) }
      row :external_round_id
    end

    panel "Results" do
      table_for resource.round_results.includes(:athlete).order(:rank) do
        column :rank
        column("Athlete") { |r| link_to "#{r.athlete.first_name} #{r.athlete.last_name}", admin_athlete_path(r.athlete) }
        column :score_raw
        column :tops
        column :zones
        column :top_attempts
        column :zone_attempts
        column :lead_height
        column :lead_plus
        column :speed_time
      end
    end
  end
end
