require "test_helper"

class Admin::Users::RolesControllerTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  setup do
    @admin = users(:admin)
    @user = users(:one)
  end

  test "guest is redirected to sign in" do
    patch admin_user_role_path(@user), params: { role: "admin" }
    assert_redirected_to new_session_path
  end

  test "non-admin is redirected to root" do
    sign_in_as(@user)
    patch admin_user_role_path(@user), params: { role: "admin" }
    assert_redirected_to root_path
  end

  test "admin can promote another user to admin" do
    sign_in_as(@admin)
    patch admin_user_role_path(@user), params: { role: "admin" }

    assert_redirected_to admin_users_path
    assert_equal "admin", @user.reload.role
  end

  test "admin can demote another admin back to default" do
    other_admin = User.create!(email_address: "other-admin@example.com", full_name: "Other Admin", role: :admin, password: "password")

    sign_in_as(@admin)
    patch admin_user_role_path(other_admin), params: { role: "default" }

    assert_equal "default", other_admin.reload.role
  end

  test "admin can change their own role" do
    sign_in_as(@admin)
    patch admin_user_role_path(@admin), params: { role: "default" }

    assert_equal "default", @admin.reload.role
  end

  test "invalid role value is rejected without a 500" do
    sign_in_as(@admin)
    patch admin_user_role_path(@user), params: { role: "superadmin" }

    assert_redirected_to admin_users_path
    assert_equal "default", @user.reload.role
  end

  test "changing a role broadcasts updated dashboard stats" do
    sign_in_as(@admin)

    messages = capture_broadcasts("dashboard_stats") do
      patch admin_user_role_path(@user), params: { role: "admin" }
    end

    assert_equal [ as_broadcast_json(Dashboard::StatsQuery.new.call) ], messages
  end

  test "an invalid role value does not broadcast dashboard stats" do
    sign_in_as(@admin)

    assert_no_broadcasts("dashboard_stats") do
      patch admin_user_role_path(@user), params: { role: "superadmin" }
    end
  end
end
