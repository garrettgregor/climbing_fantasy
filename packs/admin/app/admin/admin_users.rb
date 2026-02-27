ActiveAdmin.register(AdminUser) do
  menu priority: 10, parent: "Admin"

  permit_params :email, :password, :password_confirmation, :role

  index do
    selectable_column
    id_column
    column :email
    column :role
    column :sign_in_count
    column :current_sign_in_at
    column :created_at
    actions
  end

  filter :email
  filter :role, as: :select, collection: AdminUser.roles
  filter :created_at

  form do |f|
    f.inputs do
      f.input(:email)
      f.input(:password)
      f.input(:password_confirmation)
      f.input(:role, as: :select, collection: AdminUser.roles.keys)
    end
    f.actions
  end

  show do
    attributes_table do
      row :email
      row :role
      row :sign_in_count
      row :current_sign_in_at
      row :last_sign_in_at
      row :created_at
      row :updated_at
    end
  end
end
