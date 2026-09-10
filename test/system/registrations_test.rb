require "application_system_test_case"

class RegistrationsTest < ApplicationSystemTestCase
  test "a visitor can register and lands on their own profile as a default User" do
    visit new_registration_path
    fill_in "Full name", with: "New Visitor"
    fill_in "Email address", with: "visitor@example.com"
    fill_in "Password", with: "password"
    settle_after_fill!
    click_button "Sign up"

    assert_selector "h1", text: "New Visitor"

    user = User.find_by(email_address: "visitor@example.com")
    assert user.present?
    assert_predicate user, :default?
  end

  test "registering with a taken email shows an error and creates no User" do
    existing = users(:one)

    visit new_registration_path
    fill_in "Full name", with: "Duplicate"
    fill_in "Email address", with: existing.email_address
    fill_in "Password", with: "password"
    settle_after_fill!

    assert_no_difference "User.count" do
      click_button "Sign up"
      assert_text "has already been taken"
    end
  end
end
