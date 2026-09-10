require "application_system_test_case"

class PasswordsTest < ApplicationSystemTestCase
  test "requesting a reset sends an email and shows a generic confirmation" do
    user = users(:one)

    visit new_password_path
    fill_in "Email address", with: user.email_address
    settle_after_fill!

    perform_enqueued_jobs do
      click_button "Email reset instructions"
      # Asserting inside the block (rather than after it) matters here: perform_enqueued_jobs
      # performs whatever's enqueued by the time the block *returns*, but click_button itself
      # only waits for the click to register, not for the POST it triggers to actually land
      # server-side and enqueue the mailer job - Capybara's own retry-until-true wait on this
      # assertion is what actually gives that request time to complete first.
      assert_selector "h1", text: "Sign in"
      assert_text "Password reset instructions sent"
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [ user.email_address ], ActionMailer::Base.deliveries.last.to
  end

  test "resetting via the token signs the user in with the new password" do
    user = users(:one)

    visit edit_password_path(user.password_reset_token)
    fill_in "New password", with: "new-password"
    fill_in "Confirm new password", with: "new-password"
    settle_after_fill!
    click_button "Reset password"

    assert_selector "h1", text: "Sign in"
    assert_text "Password has been reset."

    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "new-password"
    settle_after_fill!
    click_button "Sign in"

    assert_selector "h1", text: user.full_name
  end

  test "a mismatched confirmation is caught client-side and never reaches the server" do
    user = users(:one)

    visit edit_password_path(user.password_reset_token)
    fill_in "New password", with: "new-password"
    fill_in "Confirm new password", with: "something-else"
    settle_after_fill!
    click_button "Reset password"

    # passwordsEditSchema's .refine mirrors PasswordsController#update's own mismatch check -
    # this never reaches the server at all, so the page never navigates away from the form.
    assert_text "doesn't match"
    assert_selector "h1", text: "Reset your password"
    assert user.reload.authenticate("password")
  end

  test "an invalid token redirects with an error instead of showing the reset form" do
    visit edit_password_path("not-a-real-token")

    assert_selector "h1", text: "Forgot your password?"
    assert_text "Password reset link is invalid or has expired."
  end
end
