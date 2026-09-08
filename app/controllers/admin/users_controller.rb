module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: %i[edit update destroy]

    def index
      render inertia: "admin/users/index", props: { users: users_json }
    end

    def new
      render inertia: "admin/users/new"
    end

    def create
      @user = ::Users::Inviter.new(email_address: params[:email_address], full_name: params[:full_name]).call

      if @user.persisted?
        ::Users::AvatarAssigner.new(@user, file: avatar_params[:avatar_image], url: avatar_params[:avatar_image_url]).call
        redirect_to admin_users_path, notice: "User invited."
      else
        redirect_to new_admin_user_path, inertia: { errors: @user.errors }
      end
    end

    def edit
      render inertia: "admin/users/edit", props: { user: @user.profile_json }
    end

    def update
      if @user.update(user_params)
        if ::Users::AvatarAssigner.new(@user, file: avatar_params[:avatar_image], url: avatar_params[:avatar_image_url]).call
          redirect_to admin_users_path, notice: "User updated."
        else
          redirect_to edit_admin_user_path(@user), inertia: { errors: @user.errors }
        end
      else
        redirect_to edit_admin_user_path(@user), inertia: { errors: @user.errors }
      end
    end

    def destroy
      @user.destroy
      redirect_to admin_users_path, notice: "User deleted."
    end

    private
      def set_user
        @user = User.find(params[:id])
      end

      # role is deliberately never permitted here — only
      # Admin::Users::RolesController may change it.
      def user_params
        params.permit(:email_address, :full_name)
      end

      def avatar_params
        params.permit(:avatar_image, :avatar_image_url)
      end

      def users_json
        User.order(:email_address).map(&:profile_json)
      end
  end
end
