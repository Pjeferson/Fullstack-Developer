require "test_helper"

module Imports
  class UserBatchInserterTest < ActiveSupport::TestCase
    test "inserts every row in an all-valid batch" do
      rows = [
        { "email_address" => "new1@example.com", "full_name" => "New One" },
        { "email_address" => "new2@example.com", "full_name" => "New Two" }
      ]

      result = UserBatchInserter.new(rows).call

      assert_equal 2, result.inserted_count
      assert_empty result.failed_rows
      assert User.exists?(email_address: "new1@example.com")
      assert User.exists?(email_address: "new2@example.com")
    end

    test "a row whose email already belongs to an existing User is reported as a duplicate" do
      rows = [
        { "email_address" => users(:one).email_address, "full_name" => "Someone Else" },
        { "email_address" => "new@example.com", "full_name" => "New User" }
      ]

      result = UserBatchInserter.new(rows).call

      assert_equal 1, result.inserted_count
      assert_equal 1, result.failed_rows.size
      assert_equal "email already in use", result.failed_rows.first.last
      assert_equal "User One", users(:one).reload.full_name # untouched
      assert User.exists?(email_address: "new@example.com")
    end

    test "a row that fails RowValidator is reported with that reason and never reaches insert_all" do
      rows = [
        { "email_address" => "not-an-email", "full_name" => "Bad Row" },
        { "email_address" => "new@example.com", "full_name" => "New User" }
      ]

      result = UserBatchInserter.new(rows).call

      assert_equal 1, result.inserted_count
      assert_equal 1, result.failed_rows.size
      bad_row, reason = result.failed_rows.first
      assert_equal "not-an-email", bad_row["email_address"]
      assert_equal "email is invalid", reason
      assert_not User.exists?(full_name: "Bad Row")
    end

    test "a batch with only invalid rows never calls insert_all" do
      rows = [ { "email_address" => "", "full_name" => "" } ]

      result = UserBatchInserter.new(rows).call

      assert_equal 0, result.inserted_count
      assert_equal 1, result.failed_rows.size
    end

    test "role admin creates that User as admin" do
      rows = [ { "email_address" => "new@example.com", "full_name" => "New Admin", "role" => "admin" } ]

      UserBatchInserter.new(rows).call

      assert_predicate User.find_by!(email_address: "new@example.com"), :admin?
    end

    test "a row with no role column creates a default User" do
      rows = [ { "email_address" => "new@example.com", "full_name" => "New User" } ]

      UserBatchInserter.new(rows).call

      assert_predicate User.find_by!(email_address: "new@example.com"), :default?
    end

    test "generates one bcrypt digest per batch, not once per row" do
      rows = [
        { "email_address" => "new1@example.com", "full_name" => "New One" },
        { "email_address" => "new2@example.com", "full_name" => "New Two" }
      ]
      call_count = 0

      BCrypt::Password.stub(:create, ->(*) { call_count += 1; "fake-digest" }) do
        UserBatchInserter.new(rows).call
      end

      assert_equal 1, call_count
    end
  end
end
