require "test_helper"

module Users
  class RegistrationsControllerTest < ActionDispatch::IntegrationTest
    test "GET /register renders registration page" do
      get "/register"
      assert_response :success
      assert_select "h2", "Create Account"
    end

    test "POST registration creates user with valid params" do
      assert_difference("User.count", 1) do
        post user_registration_path, params: {
          user: {
            email: "newuser@example.com",
            password: "password123456",
            password_confirmation: "password123456",
            display_name: "NewClimber",
          },
        }
      end
      assert_redirected_to authenticated_root_path
    end

    test "POST registration with missing display_name shows errors" do
      assert_no_difference("User.count") do
        post user_registration_path, params: {
          user: {
            email: "newuser@example.com",
            password: "password123456",
            password_confirmation: "password123456",
            display_name: "",
          },
        }
      end
      assert_response :unprocessable_content
    end

    test "GET /register/availability returns available for unused values" do
      get "/register/availability", params: { display_name: "FreshClimber", email: "fresh@example.com" }, as: :json

      assert_response :success
      assert_equal true, response.parsed_body.dig("display_name", "available")
      assert_equal true, response.parsed_body.dig("email", "available")
    end

    test "GET /register/availability returns unavailable for taken values" do
      taken_user = users(:alice)

      get "/register/availability", params: { display_name: taken_user.display_name, email: taken_user.email }, as: :json

      assert_response :success
      assert_equal false, response.parsed_body.dig("display_name", "available")
      assert_equal false, response.parsed_body.dig("email", "available")
    end

    test "GET /register/availability allows current user values on account edit" do
      current_user = users(:alice)
      sign_in(current_user)

      get "/register/availability", params: { display_name: current_user.display_name, email: current_user.email }, as: :json

      assert_response :success
      assert_equal true, response.parsed_body.dig("display_name", "available")
      assert_equal true, response.parsed_body.dig("email", "available")
    end
  end
end
