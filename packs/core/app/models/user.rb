# TODO: Add these Devise modules before production launch:
#   :trackable    — sign-in count, timestamps, IPs (add 5 columns to users table)
#   :confirmable  — require email verification after registration (needs mailer)
#   :lockable     — lock account after N failed sign-in attempts (needs mailer)
class User < ApplicationRecord
  devise :database_authenticatable,
    :registerable,
    :recoverable,
    :rememberable,
    :validatable

  validates :display_name, presence: true, uniqueness: { case_sensitive: false }

  class << self
    def ransackable_attributes(_auth_object = nil)
      [
        "email",
        "display_name",
      ]
    end
  end
end

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  display_name           :string           not null
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_display_name          (display_name) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
