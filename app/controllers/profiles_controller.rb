# Every action here operates on Current.user — there is no :id/:user_id
# param anywhere in this controller, so there is no route or parameter
# that could name a different User to view, edit, or delete.
class ProfilesController < InertiaController
  def show
    render inertia: "profiles/show", props: { user: Current.user.profile_json }
  end

  def update
    if Current.user.update(profile_params)
      if ::Users::AvatarAssigner.new(Current.user, file: avatar_params[:avatar_image], url: avatar_params[:avatar_image_url]).call
        redirect_to profile_path, notice: "Profile updated."
      else
        redirect_to profile_path, inertia: { errors: Current.user.errors }
      end
    else
      redirect_to profile_path, inertia: { errors: Current.user.errors }
    end
  end

  def destroy
    user = Current.user
    terminate_session
    user.destroy
    redirect_to new_session_path, notice: "Your account has been deleted."
  end

  private
    # role is deliberately never permitted here — there is no path,
    # admin or self-service, where a User can set their own role.
    def profile_params
      params.permit(:email_address, :full_name)
    end

    def avatar_params
      params.permit(:avatar_image, :avatar_image_url)
    end
end
