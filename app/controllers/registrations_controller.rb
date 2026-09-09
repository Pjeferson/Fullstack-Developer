# Self-service Visitor registration. No service object here (unlike Users::Inviter) - there's
# no side effect (an email, a background job) to isolate from User; this is a plain
# User.new(...).save, same shape ProfilesController#update already uses for a single-record
# write.
class RegistrationsController < InertiaController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Try again later." }

  def new
    redirect_to(after_authentication_url) and return if authenticated?
    render inertia: {}
  end

  def create
    user = User.new(registration_params)

    if user.save
      start_new_session_for(user)
      ::Dashboard::StatsBroadcaster.new.call
      redirect_to after_authentication_url
    else
      redirect_to new_registration_path, inertia: { errors: user.errors }
    end
  end

  private
    # role is structurally absent - the same "not even permitted" guarantee
    # Admin::UsersController/ProfilesController already give `role` elsewhere. A registered User
    # is `default` by the enum's own default, not by a check here.
    def registration_params
      params.permit(:full_name, :email_address, :password)
    end
end
