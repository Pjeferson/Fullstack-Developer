module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: %i[update destroy]

    def index
      query = ::Admin::UsersQuery.new(before_id: params[:before_id])

      render inertia: "admin/users/index", props: {
        users: InertiaRails.scroll(query.metadata) { users_json(query.records) },
        stats: ::Dashboard::StatsQuery.new.call
      }
    end

    # No dedicated create/edit page anymore - both happen in a modal on #index. Both branches
    # below redirect back to the same index route (success or failure): the modal's open/closed
    # state lives in the frontend, not the URL, so a failure redirect with `errors` populated
    # simply re-renders the same page with the modal still open, showing them.
    def create
      @user = ::Users::Inviter.new(email_address: params[:email_address], full_name: params[:full_name]).call

      if @user.persisted?
        ::Users::AvatarAssigner.new(@user, file: avatar_params[:avatar_image], url: avatar_params[:avatar_image_url]).call
        ::Dashboard::StatsBroadcaster.new.call
        redirect_to admin_users_path, notice: "User invited."
      else
        redirect_to admin_users_path, inertia: { errors: @user.errors }
      end
    end

    def update
      if @user.update(user_params)
        if ::Users::AvatarAssigner.new(@user, file: avatar_params[:avatar_image], url: avatar_params[:avatar_image_url]).call
          redirect_to admin_users_path, notice: "User updated."
        else
          redirect_to admin_users_path, inertia: { errors: @user.errors }
        end
      else
        redirect_to admin_users_path, inertia: { errors: @user.errors }
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
      # modal and the self-service profile page, where those timestamps aren't shown.
      def users_json(users)
        users.map { |user| user.profile_json.merge(created_at: user.created_at, updated_at: user.updated_at) }
      end
  end
end
