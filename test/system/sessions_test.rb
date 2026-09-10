require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  test "an admin signing in lands on the admin user list" do
    sign_in_as(users(:admin))

    assert_selector "h1", text: "Users"
  end

  test "a non-admin signing in lands on their own profile" do
    sign_in_as(users(:one))

    assert_title "My profile"
    assert_selector "h1", text: users(:one).full_name
  end

  test "invalid credentials show an error and stay on the sign-in page" do
    visit new_session_path
    fill_in "Email address", with: users(:one).email_address
    fill_in "Password", with: "wrong password"
    settle_after_fill!
    click_button "Sign in"

    assert_selector "h1", text: "Sign in"
    assert_text "Try another email address or password."
  end

  test "sign-in links to sign-up and forgot-password" do
    visit new_session_path
    # The email field is auto-focused and blur-validated (see useValidation) - clicking the h1
    # first, before ever touching that field, blurs it and settles the "can't be blank" message
    # (and the layout shift it causes) before the click we actually care about. Skipping this
    # lets a real click's mousedown/mouseup straddle that shift and land on the wrong element.
    find("h1").click

    click_link "Sign up"
    assert_selector "h1", text: "Create your account"

    visit new_session_path
    find("h1").click
    click_link "Forgot your password?"
    assert_selector "h1", text: "Forgot your password?"
  end
end
