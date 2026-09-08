module Admin
  # Base for every controller under the /admin namespace. Authentication
  # (login required) is already enforced app-wide by ApplicationController;
  # this only adds the admin-role check on top of it.
  class BaseController < InertiaController
    before_action :require_admin

    private
      def require_admin
        return if Current.user&.admin?

        redirect_to root_path, alert: "You are not authorized to access this page."
      end
  end
end
