ActiveAdmin.register(Event) do
  menu priority: 3

  permit_params :season_id,
    :external_id,
    :name,
    :location,
    :starts_on,
    :ends_on,
    :discipline,
    :status

  scope :all
  scope :upcoming
  scope :in_progress
  scope :completed

  index do
    selectable_column
    id_column
    column :name
    column :location
    column :discipline
    column :status
    column :starts_on
    column :ends_on
    column(:season) { |e| link_to e.season.name, admin_season_path(e.season) }
    column :results_synced_at
    actions
  end

  filter :season
  filter :name
  filter :location
  filter :discipline, as: :select, collection: Event.disciplines
  filter :status, as: :select, collection: Event.statuses
  filter :starts_on

  show do
    attributes_table do
      row :name
      row :location
      row :discipline
      row :status
      row :starts_on
      row :ends_on
      row(:season) { |e| link_to e.season.name, admin_season_path(e.season) }
      row :external_id
      row :results_synced_at
      row :created_at
    end

    panel "Categories" do
      table_for resource.categories do
        column(:name) { |c| link_to c.name, admin_category_path(c) }
        column :discipline
        column :gender
        column :age_category
      end
    end
  end
end
