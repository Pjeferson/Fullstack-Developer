require "test_helper"

module Dashboard
  class StatsBroadcasterTest < ActiveSupport::TestCase
    include ActionCable::TestHelper

    test "broadcasts the current stats on the dashboard_stats stream" do
      assert_broadcast_on("dashboard_stats", Dashboard::StatsQuery.new.call) do
        StatsBroadcaster.new.call
      end
    end
  end
end
