require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  setup do
    @admin = users(:admin)
    @user = users(:one)
  end

  test "guest is redirected to sign in" do
    get admin_users_path
    assert_redirected_to new_session_path
  end

  test "non-admin is redirected to root" do
    sign_in_as(@user)
    get admin_users_path
    assert_redirected_to root_path
  end

  test "admin can list users" do
    sign_in_as(@admin)
    get admin_users_path
    assert_response :success
    assert_inertia_component "admin/users/index"
    assert_inertia_props { |props| props[:users].map { |u| u[:id] }.include?(@user.id) }
  end

  test "the user list includes created_at and updated_at, newest first" do
    sign_in_as(@admin)
    get admin_users_path

    assert_inertia_props do |props|
      ids = props[:users].map { |u| u[:id] }
      user_row = props[:users].find { |u| u[:id] == @user.id }

      ids == ids.sort.reverse &&
        user_row[:created_at].present? &&
        user_row[:updated_at].present?
    end
  end

  test "admin can view the new user form" do
    sign_in_as(@admin)
    get new_admin_user_path
    assert_response :success
    assert_inertia_component "admin/users/new"
  end

  test "admin can invite a new user" do
    sign_in_as(@admin)

    assert_difference "User.count", 1 do
      post admin_users_path, params: { email_address: "invitee@example.com", full_name: "Invitee" }
    end

    assert_redirected_to admin_users_path
    assert User.find_by(email_address: "invitee@example.com").present?
  end

  test "inviting a user broadcasts updated dashboard stats" do
    sign_in_as(@admin)

    messages = capture_broadcasts("dashboard_stats") do
      post admin_users_path, params: { email_address: "invitee@example.com", full_name: "Invitee" }
    end

    assert_equal [ as_broadcast_json(Dashboard::StatsQuery.new.call) ], messages
  end

  test "a failed invite does not broadcast dashboard stats" do
    sign_in_as(@admin)

    assert_no_broadcasts("dashboard_stats") do
      post admin_users_path, params: { email_address: "", full_name: "" }
    end
  end

  test "role param is ignored on create" do
    sign_in_as(@admin)

    post admin_users_path, params: { email_address: "invitee@example.com", full_name: "Invitee", role: "admin" }

    assert_equal "default", User.find_by(email_address: "invitee@example.com").role
  end

  test "invalid attributes redirect back with errors" do
    sign_in_as(@admin)

    assert_no_difference "User.count" do
      post admin_users_path, params: { email_address: "", full_name: "" }
    end

    assert_redirected_to new_admin_user_path
  end

  test "admin can view the edit form" do
    sign_in_as(@admin)
    get edit_admin_user_path(@user)
    assert_response :success
    assert_inertia_component "admin/users/edit"
    assert_inertia_props { |props| props[:user][:id] == @user.id }
  end

  test "admin can update a user" do
    sign_in_as(@admin)

    patch admin_user_path(@user), params: { email_address: @user.email_address, full_name: "Updated Name" }

    assert_redirected_to admin_users_path
    assert_equal "Updated Name", @user.reload.full_name
  end

  test "a plain edit does not broadcast dashboard stats" do
    sign_in_as(@admin)

    assert_no_broadcasts("dashboard_stats") do
      patch admin_user_path(@user), params: { email_address: @user.email_address, full_name: "Updated Name" }
    end
  end

  test "role param is ignored on update" do
    sign_in_as(@admin)

    patch admin_user_path(@user), params: { email_address: @user.email_address, full_name: @user.full_name, role: "admin" }

    assert_equal "default", @user.reload.role
  end

  test "admin can delete a user" do
    sign_in_as(@admin)

    assert_difference "User.count", -1 do
      delete admin_user_path(@user)
    end

    assert_redirected_to admin_users_path
  end

  test "admin can delete their own account" do
    sign_in_as(@admin)

    assert_difference "User.count", -1 do
      delete admin_user_path(@admin)
    end
  end

  test "deleting a user broadcasts updated dashboard stats" do
    sign_in_as(@admin)

    messages = capture_broadcasts("dashboard_stats") do
      delete admin_user_path(@user)
    end

    assert_equal [ as_broadcast_json(Dashboard::StatsQuery.new.call) ], messages
  end
end
