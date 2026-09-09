require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionCable::TestHelper

  setup { @user = users(:one) }

  test "guest is redirected to sign in" do
    get profile_path
    assert_redirected_to new_session_path
  end

  test "signed-in user can view their own profile" do
    sign_in_as(@user)
    get profile_path
    assert_response :success
    assert_inertia_component "profiles/show"
    assert_inertia_props { |props| props[:user][:id] == @user.id }
  end

  test "user can update their own profile" do
    sign_in_as(@user)

    patch profile_path, params: { email_address: @user.email_address, full_name: "Updated Name" }

    assert_redirected_to profile_path
    assert_equal "Updated Name", @user.reload.full_name
  end

  test "role param is ignored on update" do
    sign_in_as(@user)

    patch profile_path, params: { email_address: @user.email_address, full_name: @user.full_name, role: "admin" }

    assert_equal "default", @user.reload.role
  end

  test "invalid update redirects back with errors" do
    sign_in_as(@user)

    patch profile_path, params: { email_address: "", full_name: "" }

    assert_redirected_to profile_path
    assert_equal "one@example.com", @user.reload.email_address
  end

  test "email must not collide with another user" do
    sign_in_as(@user)
    other = users(:two)

    patch profile_path, params: { email_address: other.email_address, full_name: @user.full_name }

    assert_not_equal other.email_address, @user.reload.email_address
  end

  test "user can attach an avatar from an uploaded file" do
    sign_in_as(@user)

    patch profile_path, params: {
      email_address: @user.email_address,
      full_name: @user.full_name,
      avatar_image: fixture_file_upload("avatar.png", "image/png")
    }

    assert_redirected_to profile_path
    assert @user.reload.avatar_image.attached?
  end

  test "user can attach an avatar from a url" do
    sign_in_as(@user)

    assert_enqueued_with(job: AttachRemoteAvatarJob, args: [ @user.id, "https://example.com/avatar.png" ]) do
      patch profile_path, params: {
        email_address: @user.email_address,
        full_name: @user.full_name,
        avatar_image_url: "https://example.com/avatar.png"
      }
    end

    assert @user.reload.avatar_processing?
  end

  test "rejected avatar upload redirects back with an error" do
    sign_in_as(@user)

    patch profile_path, params: {
      email_address: @user.email_address,
      full_name: @user.full_name,
      avatar_image: fixture_file_upload("not_an_image.txt", "text/plain")
    }

    assert_redirected_to profile_path
    assert_not @user.reload.avatar_image.attached?
  end

  test "user can delete their own account" do
    sign_in_as(@user)

    assert_difference "User.count", -1 do
      delete profile_path
    end

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "deleting the account broadcasts updated dashboard stats" do
    sign_in_as(@user)

    messages = capture_broadcasts("dashboard_stats") do
      delete profile_path
    end

    assert_equal [ as_broadcast_json(Dashboard::StatsQuery.new.call) ], messages
  end

  test "deleting the account also removes the session record and the avatar attachment" do
    sign_in_as(@user)
    @user.avatar_image.attach(fixture_file_upload("avatar.png", "image/png"))
    session_id = Current.session.id

    assert_enqueued_with(job: ActiveStorage::PurgeJob) do
      delete profile_path
    end

    assert_not Session.exists?(session_id)
    assert_not ActiveStorage::Attachment.exists?(record_type: "User", record_id: @user.id)
  end
end
