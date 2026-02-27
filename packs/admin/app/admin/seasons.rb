ActiveAdmin.register(Season) do
  menu priority: 2

  permit_params :external_id, :name, :year

  index do
    selectable_column
    id_column
    column :name
    column :year
    column :external_id
    column("Events") { |s| s.events.count }
    column :created_at
    actions
  end

  filter :name
  filter :year
  filter :external_id

  show do
    attributes_table do
      row :name
      row :year
      row :external_id
      row :created_at
      row :updated_at
    end

    panel "Events" do
      table_for resource.events.order(:starts_on) do
        column(:name) { |e| link_to e.name, admin_event_path(e) }
        column :location
        column :discipline
        column :status
        column :starts_on
        column :ends_on
        column :results_synced_at
      end
    end
  end
end
