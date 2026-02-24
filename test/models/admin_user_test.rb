require "test_helper"

class AdminUserTest < ActiveSupport::TestCase
  # Validations (Devise handles email/password)
  should validate_presence_of(:role)

  # Enums
  test "role enum values" do
    assert_equal %w[viewer admin super_admin], AdminUser.roles.keys
  end

  test "default role is viewer" do
    user = AdminUser.new(email: "test@example.com", password: "password123456")
    assert_equal "viewer", user.role
  end

  test "super_admin fixture" do
    admin = admin_users(:super_admin)
    assert admin.super_admin?
    assert_equal "admin@climbingfantasy.com", admin.email
  end
end
