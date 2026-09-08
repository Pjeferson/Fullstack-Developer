require "test_helper"

class AttachRemoteAvatarJobTest < ActiveJob::TestCase
  FakeSsrfResponse = Struct.new(:body, :content_type) do
    def [](key)
      key == "content-type" ? content_type : nil
    end
  end

  setup { @user = users(:one) }

  test "attaches the downloaded image on success" do
    response = FakeSsrfResponse.new(file_fixture("avatar.png").read, "image/png")

    SsrfFilter.stub :get, response do
      AttachRemoteAvatarJob.perform_now(@user.id, "https://example.com/avatar.png")
    end

    @user.reload
    assert @user.avatar_image.attached?
    assert_not @user.avatar_processing?
    assert_nil @user.avatar_error
  end

  test "records the error and does not attach when the url is blocked" do
    SsrfFilter.stub :get, ->(*) { raise SsrfFilter::PrivateIPAddress, "blocked address" } do
      AttachRemoteAvatarJob.perform_now(@user.id, "http://169.254.169.254/")
    end

    @user.reload
    assert_not @user.avatar_image.attached?
    assert_not @user.avatar_processing?
    assert_match "blocked address", @user.avatar_error
  end

  test "records the error for a disallowed content type" do
    response = FakeSsrfResponse.new("not an image", "text/plain")

    SsrfFilter.stub :get, response do
      AttachRemoteAvatarJob.perform_now(@user.id, "https://example.com/file.txt")
    end

    @user.reload
    assert_not @user.avatar_image.attached?
    assert_match "unsupported content type", @user.avatar_error
  end

  test "discards the job when the user no longer exists" do
    assert_nothing_raised do
      AttachRemoteAvatarJob.perform_now(-1, "https://example.com/avatar.png")
    end
  end
end
