require "test_helper"

class Users::InviterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "creates a persisted user with an unusable random password" do
    user = Users::Inviter.call(email_address: "invitee@example.com", full_name: "Invitee")

    assert user.persisted?
    assert_not user.authenticate("anything")
    assert_not user.authenticate("")
  end

  test "sends a password-reset email so the invitee can set their own password" do
    perform_enqueued_jobs do
      Users::Inviter.call(email_address: "invitee@example.com", full_name: "Invitee")
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [ "invitee@example.com" ], email.to
  end

  test "returns an unpersisted user with errors when attributes are invalid" do
    user = Users::Inviter.call(email_address: users(:one).email_address, full_name: "Duplicate")

    assert_not user.persisted?
    assert_includes user.errors[:email_address], "has already been taken"
  end
end
