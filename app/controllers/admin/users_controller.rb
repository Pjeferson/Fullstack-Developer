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
      @user = Users::Inviter.call(email_address: params[:email_address], full_name: params[:full_name])

      if @user.persisted?
        Users::AvatarAssigner.new(@user, file: avatar_params[:avatar_image], url: avatar_params[:avatar_image_url]).call
        redirect_to admin_users_path, notice: "User invited."
      else
        redirect_to new_admin_user_path, inertia: { errors: @user.errors }
      end
    end

    def edit
      render inertia: "admin/users/edit", props: { user: user_json(@user) }
    end

    def update
      if @user.update(user_params)
        if Users::AvatarAssigner.new(@user, file: avatar_params[:avatar_image], url: avatar_params[:avatar_image_url]).call
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
        User.order(:email_address).map { |user| user_json(user) }
      end

      def user_json(user)
        user.as_json(only: %i[id email_address full_name role avatar_processing avatar_error], methods: %i[avatar_url])
      end
  end
end
