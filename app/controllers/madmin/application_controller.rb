module Madmin
  class ApplicationController < Madmin::BaseController
    include Authentication

    before_action :authenticate_admin_user

    private

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to main_app.new_session_path
    end

    def authenticate_admin_user
      return if Current.user&.admin?

      redirect_to main_app.root_path, alert: I18n.t("unauthorized")
    end
  end
end
