require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test "connects and identifies current_user with a valid signed session cookie" do
      session = users(:one).sessions.create!
      cookies.signed[:session_id] = session.id

      connect

      assert_equal users(:one), connection.current_user
    end

    test "rejects the connection with no session cookie" do
      assert_reject_connection { connect }
    end

    test "rejects the connection with an invalid session cookie" do
      cookies.signed[:session_id] = -1

      assert_reject_connection { connect }
    end
  end
end
