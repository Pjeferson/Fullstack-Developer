require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "an already-authenticated user visiting new is redirected to their landing page" do
    sign_in_as(@user)
    get new_session_path
    assert_redirected_to profile_path
  end

  test "an already-authenticated admin visiting new is redirected to the admin user list" do
    sign_in_as(users(:admin))
    get new_session_path
    assert_redirected_to admin_users_path
  end

  test "create with valid credentials redirects a non-admin to their profile" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to profile_path
    assert cookies[:session_id]
  end

  test "create with valid credentials redirects an admin to the admin user list" do
    admin = users(:admin)

    post session_path, params: { email_address: admin.email_address, password: "password" }

    assert_redirected_to admin_users_path
    assert cookies[:session_id]
  end

  test "return_to_after_authenticating takes precedence over the role-based redirect" do
    get admin_users_path # unauthenticated: remembers this as the return-to URL
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "password" }

    # @user is not an admin, so the role-based fallback would have been
    # profile_path — confirms the remembered URL wins over it.
    assert_redirected_to admin_users_path
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(@user)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
