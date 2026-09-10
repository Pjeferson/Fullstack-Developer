module SystemTestAuthenticationHelper
  # Unlike SessionTestHelper#sign_in_as (controller/integration tests), a system test is a real,
  # separate browser process with its own cookie jar - there's no internal test cookie jar to
  # write into directly, so this drives the real sign-in form instead.
  def sign_in_as(user, password: "password")
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: password
    settle_after_fill!
    click_button "Sign in"
    # Waits for the post-sign-in redirect to actually land before returning control to the
    # caller - without this, a caller that immediately does a fresh `visit` (rather than an
    # assertion, which would retry on its own) can race ahead of the session cookie being set
    # and land back on the sign-in page.
    assert_no_selector "h1", text: "Sign in"
  end
end

ActiveSupport.on_load(:action_dispatch_system_test_case) do
  include SystemTestAuthenticationHelper
end
