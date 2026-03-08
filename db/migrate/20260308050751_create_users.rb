class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table(:users) do |t|
      # Devise: database_authenticatable
      t.string(:email, null: false, default: "")
      t.string(:encrypted_password, null: false, default: "")

      # Devise: recoverable
      t.string(:reset_password_token)
      t.datetime(:reset_password_sent_at)

      # Devise: rememberable
      t.datetime(:remember_created_at)

      # Profile
      t.string(:display_name, null: false)

      t.timestamps
    end

    add_index(:users, :email, unique: true)
    add_index(:users, :display_name, unique: true)
    add_index(:users, :reset_password_token, unique: true)
  end
end
