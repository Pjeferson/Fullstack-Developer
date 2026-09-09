ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "inertia_rails/minitest"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Round-trips a broadcast payload through JSON the same way
    # ActionCable::TestHelper's own assertions do, so a Hash with symbol keys
    # (e.g. Dashboard::StatsQuery#call) can be compared against a captured,
    # already-JSON-decoded broadcast message.
    def as_broadcast_json(data)
      ActiveSupport::JSON.decode(ActiveSupport::JSON.encode(data))
    end
  end
end
