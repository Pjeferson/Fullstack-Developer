require "test_helper"

class DashboardChannelTest < ActionCable::Channel::TestCase
  test "an admin subscribing is confirmed and streaming" do
    stub_connection current_user: users(:admin)

    subscribe

    assert subscription.confirmed?
    assert_has_stream "dashboard_stats"
  end

  test "a non-admin is rejected" do
    stub_connection current_user: users(:one)

    subscribe

    assert subscription.rejected?
  end
end
