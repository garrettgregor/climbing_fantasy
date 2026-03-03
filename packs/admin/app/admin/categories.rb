ActiveAdmin.register(Category) do
  menu priority: 5

  permit_params :event_id,
    :external_id,
    :name,
    :discipline,
    :gender

  index do
    selectable_column
    id_column
    column :name
    column :discipline
    column :gender
    column(:event) { |c| link_to c.event.name, admin_event_path(c.event) }
    actions
  end

  filter :event
  filter :name
  filter :discipline, as: :select, collection: Category.disciplines
  filter :gender, as: :select, collection: Category.genders

  show do
    attributes_table do
      row :name
      row :discipline
      row :gender
      row(:event) { |c| link_to c.event.name, admin_event_path(c.event) }
      row :external_id
    end

    panel "Rounds" do
      table_for resource.rounds.order(:round_type) do
        column(:name) { |r| link_to r.name, admin_round_path(r) }
        column :round_type
        column :status
        column("Results") { |r| r.round_results.count }
      end
    end
  end
end
