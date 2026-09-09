require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  setup { @user = users(:one) }

  test "guest can view the registration form" do
    get new_registration_path
    assert_response :success
  end

  test "an already-authenticated user visiting new is redirected to their landing page" do
    sign_in_as(@user)
    get new_registration_path
    assert_redirected_to profile_path
  end

  test "an already-authenticated admin visiting new is redirected to the admin user list" do
    sign_in_as(users(:admin))
    get new_registration_path
    assert_redirected_to admin_users_path
  end

  test "a visitor can register and is signed in as a default user, redirected to their profile" do
    assert_difference "User.count", 1 do
      post registration_path, params: {
        full_name: "New Visitor", email_address: "visitor@example.com", password: "password"
      }
    end

    user = User.find_by!(email_address: "visitor@example.com")
    assert_predicate user, :default?
    assert_redirected_to profile_path
    assert cookies[:session_id]
  end

  test "role param is ignored on registration" do
    post registration_path, params: {
      full_name: "New Visitor", email_address: "visitor@example.com", password: "password", role: "admin"
    }

    assert_equal "default", User.find_by(email_address: "visitor@example.com").role
  end

  test "a blank or duplicate email is rejected and creates no user" do
    assert_no_difference "User.count" do
      post registration_path, params: { full_name: "New Visitor", email_address: "", password: "password" }
    end
    assert_no_difference "User.count" do
      post registration_path, params: {
        full_name: "New Visitor", email_address: @user.email_address, password: "password"
      }
    end

    assert_redirected_to new_registration_path
    assert_nil cookies[:session_id]
  end

  test "a blank full name is rejected and creates no user" do
    assert_no_difference "User.count" do
      post registration_path, params: { full_name: "", email_address: "visitor@example.com", password: "password" }
    end

    assert_redirected_to new_registration_path
  end

  test "a blank password is rejected and creates no user" do
    assert_no_difference "User.count" do
      post registration_path, params: { full_name: "New Visitor", email_address: "visitor@example.com", password: "" }
    end

    assert_redirected_to new_registration_path
  end

  test "a successful registration broadcasts updated dashboard stats" do
    messages = capture_broadcasts("dashboard_stats") do
      post registration_path, params: {
        full_name: "New Visitor", email_address: "visitor@example.com", password: "password"
      }
    end

    assert_equal [ as_broadcast_json(Dashboard::StatsQuery.new.call) ], messages
  end

  test "a failed registration does not broadcast dashboard stats" do
    assert_no_broadcasts("dashboard_stats") do
      post registration_path, params: { full_name: "", email_address: "", password: "" }
    end
  end
end
