require "test_helper"

class Users::AvatarAssignerTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile
  include ActiveJob::TestHelper

  setup { @user = users(:one) }

  test "does nothing when neither file nor url given" do
    assert Users::AvatarAssigner.new(@user).call
    assert_not @user.avatar_image.attached?
  end

  test "attaches an uploaded file synchronously" do
    file = fixture_file_upload("avatar.png", "image/png")

    assert Users::AvatarAssigner.new(@user, file: file).call
    assert @user.avatar_image.attached?
    assert_not @user.avatar_processing?
  end

  test "rejects a disallowed content type" do
    file = fixture_file_upload("not_an_image.txt", "text/plain")

    assert_not Users::AvatarAssigner.new(@user, file: file).call
    assert_not @user.avatar_image.attached?
    assert_includes @user.errors[:avatar_image], "must be PNG, JPEG, WEBP, or GIF"
  end

  test "rejects an oversized file" do
    file = fixture_file_upload("avatar.png", "image/png")
    file.stub :size, Users::AvatarAssigner::MAX_SIZE + 1 do
      assert_not Users::AvatarAssigner.new(@user, file: file).call
    end
    assert_not @user.avatar_image.attached?
    assert_includes @user.errors[:avatar_image], "must be smaller than 5MB"
  end

  test "enqueues a download job for a url and marks the user as processing" do
    assert_enqueued_with(job: AttachRemoteAvatarJob, args: [ @user.id, "https://example.com/avatar.png" ]) do
      assert Users::AvatarAssigner.new(@user, url: "https://example.com/avatar.png").call
    end
    assert @user.avatar_processing?
  end
end
