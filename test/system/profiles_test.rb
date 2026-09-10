require "application_system_test_case"

class ProfilesTest < ApplicationSystemTestCase
  test "a signed-in User can view and edit their own profile" do
    user = users(:one)
    sign_in_as(user)

    assert_selector "h1", text: user.full_name
    assert_text user.email_address

    fill_in "Full name", with: "User One Edited"
    settle_after_fill!
    click_button "Save"

    assert_selector "h1", text: "User One Edited"
    assert_equal "User One Edited", user.reload.full_name
  end

  test "a User can delete their own account and lands back at sign-in" do
    user = users(:two)
    sign_in_as(user)

    click_button "Delete my account"
    within "[role=dialog]" do
      click_button "Delete"
    end

    assert_selector "h1", text: "Sign in"
    assert_not User.exists?(user.id)
  end
end
