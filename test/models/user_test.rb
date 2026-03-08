require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "validates presence of display_name" do
    user = User.new(email: "test@example.com", password: "password123456")
    assert_not user.valid?
    assert_includes user.errors[:display_name], "can't be blank"
  end

  test "validates presence of email" do
    user = User.new(display_name: "Test", password: "password123456")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "validates uniqueness of email" do
    existing = users(:alice)
    duplicate = User.new(email: existing.email, password: "password123456", display_name: "Dup")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "validates uniqueness of display_name (case-insensitive)" do
    existing = users(:alice)
    duplicate = User.new(email: "other@example.com", password: "password123456", display_name: existing.display_name.upcase)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:display_name], "has already been taken"
  end

  test "validates password minimum length" do
    user = User.new(email: "test@example.com", password: "short", display_name: "Test")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 6 characters)"
  end

  test "valid user with all attributes" do
    user = User.new(email: "new@example.com", password: "password123456", display_name: "NewUser")
    assert user.valid?
  end

  test "includes expected Devise modules" do
    expected_modules = [:database_authenticatable, :registerable, :recoverable, :rememberable, :validatable]
    expected_modules.each do |mod|
      assert_includes User.devise_modules, mod
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
