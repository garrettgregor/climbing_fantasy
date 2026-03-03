# Temporary compatibility patch for Rails 8.1+ route keyword deprecations.
# Devise 4.9.4 passes a positional options hash to `resource` in
# `devise_registration`, which emits deprecation warnings in Rails 8.1 and
# will break in Rails 8.2.
#
# Remove this patch once the app upgrades to a Devise release that fixes this.
module ActionDispatch
  module Routing
    class Mapper
      private

      def devise_registration(mapping, controllers)
        path_names = {
          new: mapping.path_names[:sign_up],
          edit: mapping.path_names[:edit],
          cancel: mapping.path_names[:cancel],
        }

        resource(
          :registration,
          only: [:new, :create, :edit, :update, :destroy],
          path: mapping.path_names[:registration],
          path_names: path_names,
          controller: controllers[:registrations],
        ) do
          get(:cancel)
        end
      end
    end
  end
end
