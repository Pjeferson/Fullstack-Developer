module Admin
  class Users::RolesController < Admin::BaseController
    before_action :set_user

    def update
      role = params.expect(:role)

      unless User.roles.key?(role)
        redirect_to admin_users_path, alert: "Invalid role." and return
      end

      @user.update!(role: role)
      ::Dashboard::StatsBroadcaster.new.call
      redirect_to admin_users_path, notice: "Role updated."
    end

    private
      def set_user
        @user = User.find(params[:user_id])
      end
  end
end
