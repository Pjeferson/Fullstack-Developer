module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: %i[edit update destroy]

    def index
      query = ::Admin::UsersQuery.new(before_id: params[:before_id])

      render inertia: "admin/users/index", props: {
        users: InertiaRails.scroll(query.metadata) { users_json(query.records) },
        stats: ::Dashboard::StatsQuery.new.call
      }
    end

    def new
      render inertia: "admin/users/new"
    end

    def create
      @user = ::Users::Inviter.new(email_address: params[:email_address], full_name: params[:full_name]).call

      if @user.persisted?
        ::Users::AvatarAssigner.new(@user, file: avatar_params[:avatar_image], url: avatar_params[:avatar_image_url]).call
        ::Dashboard::StatsBroadcaster.new.call
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
      ::Dashboard::StatsBroadcaster.new.call
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

      # Listing-only fields (created_at/updated_at) are merged on top of profile_json here
      # rather than added to profile_json itself, since profile_json is shared with the edit
      # form and the self-service profile page, where those timestamps aren't shown.
      def users_json(users)
        users.map { |user| user.profile_json.merge(created_at: user.created_at, updated_at: user.updated_at) }
      end
  end
end
