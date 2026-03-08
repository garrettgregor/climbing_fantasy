class DashboardController < ApplicationController
  layout "auth"

  before_action :authenticate_user!
end
