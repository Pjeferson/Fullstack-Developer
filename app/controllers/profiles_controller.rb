# Every action here operates on Current.user — there is no :id/:user_id
# param anywhere in this controller, so there is no route or parameter
# that could name a different User to view or edit.
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
