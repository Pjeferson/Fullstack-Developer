require "application_system_test_case"

class Admin::UsersTest < ApplicationSystemTestCase
  test "the full admin User CRUD flow in one session" do
    sign_in_as(users(:admin))
    assert_selector "h1", text: "Users"
    assert_text users(:one).full_name

    # Create (invite)
    click_button "New user"
    within "[role=dialog]" do
      assert_text "Invite a user"
      fill_in "Full name", with: "Carol Newperson"
      fill_in "Email address", with: "carol@example.com"
      settle_after_fill!
      click_button "Send invite"
    end
    assert_no_selector "[role=dialog]"
    assert_text "Carol Newperson"

    # Edit
    within "tr", text: "Carol Newperson" do
      click_button "Edit"
    end
    within "[role=dialog]" do
      assert_text "Edit user"
      fill_in "Full name", with: "Carol Editedperson"
      settle_after_fill!
      click_button "Save"
    end
    assert_no_selector "[role=dialog]"
    assert_text "Carol Editedperson"
    assert_no_text "Carol Newperson"

    # Promote / demote
    within "tr", text: "Carol Editedperson" do
      assert_text "Member"
      click_button "Promote"
    end
    within "tr", text: "Carol Editedperson" do
      assert_text "Admin"
      click_button "Demote"
    end
    within "tr", text: "Carol Editedperson" do
      assert_text "Member"
    end

    # Delete
    within "tr", text: "Carol Editedperson" do
      click_button "Delete"
    end
    within "[role=dialog]" do
      assert_text "Delete user"
      click_button "Delete"
    end
    assert_no_selector "[role=dialog]"
    assert_no_text "Carol Editedperson"
  end

  test "a non-admin cannot reach the admin user list" do
    sign_in_as(users(:one))
    visit admin_users_path

    assert_no_selector "h1", text: "Users"
  end
end
