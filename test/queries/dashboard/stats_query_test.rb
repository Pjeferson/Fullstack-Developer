require "test_helper"

module Dashboard
  class StatsQueryTest < ActiveSupport::TestCase
    test "returns the total and per-role counts" do
      stats = StatsQuery.new.call

      assert_equal User.count, stats[:total]
      assert_equal User.default.count, stats[:by_role]["default"]
      assert_equal User.admin.count, stats[:by_role]["admin"]
    end

    test "a role with zero Users is present in by_role as 0, not omitted" do
      User.admin.destroy_all

      stats = StatsQuery.new.call

      assert_equal 0, stats[:by_role]["admin"]
    end
  end
end
