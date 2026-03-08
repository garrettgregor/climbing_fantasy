module Users
  class RegistrationsController < Devise::RegistrationsController
    layout "auth"

    def availability
      render(json: {
        display_name: display_name_availability(params[:display_name]),
        email: email_availability(params[:email]),
      })
    end

    private

    def availability_scope
      return User.where.not(id: current_user.id) if user_signed_in?

      User.all
    end

    def display_name_availability(value)
      normalized_value = value.to_s.strip
      return availability_response(nil, "") if normalized_value.blank?
      return availability_response(nil, "Display name must be at least 3 characters") if normalized_value.length < 3

      taken = availability_scope.exists?(["LOWER(display_name) = ?", normalized_value.downcase])
      return availability_response(false, "Display name is already taken") if taken

      availability_response(true, "Display name is available")
    end

    def email_availability(value)
      normalized_value = value.to_s.strip.downcase
      return availability_response(nil, "") if normalized_value.blank?
      return availability_response(nil, "Enter a valid email address") unless normalized_value.match?(URI::MailTo::EMAIL_REGEXP)

      taken = availability_scope.exists?(["LOWER(email) = ?", normalized_value])
      return availability_response(false, "Email is already registered") if taken

      availability_response(true, "Email is available")
    end

    def availability_response(available, message)
      { available:, message: }
    end

    # Devise requires these to return ActionController::Parameters;
    # params.expect returns an array for scalar keys, which breaks Devise internals.
    def sign_up_params
      params.require(:user).permit(:email, :password, :password_confirmation, :display_name) # rubocop:disable Rails/StrongParametersExpect
    end

    def account_update_params
      params.require(:user).permit(:email, :password, :password_confirmation, :current_password, :display_name) # rubocop:disable Rails/StrongParametersExpect
    end
  end
end
