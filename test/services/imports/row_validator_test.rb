require "test_helper"

module Imports
  class RowValidatorTest < ActiveSupport::TestCase
    test "a fully valid row is valid" do
      row = RowValidator.new({ "email_address" => "new@example.com", "full_name" => "New User", "role" => nil })

      assert_predicate row, :valid?
      assert_empty row.errors
    end

    test "a blank email is invalid" do
      row = RowValidator.new({ "email_address" => "", "full_name" => "New User" })

      assert_not row.valid?
      assert_includes row.errors, "email is invalid"
    end

    test "a malformed email is invalid" do
      row = RowValidator.new({ "email_address" => "not-an-email", "full_name" => "New User" })

      assert_not row.valid?
      assert_includes row.errors, "email is invalid"
    end

    test "a blank full name is invalid" do
      row = RowValidator.new({ "email_address" => "new@example.com", "full_name" => "" })

      assert_not row.valid?
      assert_includes row.errors, "full name can't be blank"
    end

    test "a missing or blank role is valid" do
      assert_predicate RowValidator.new({ "email_address" => "new@example.com", "full_name" => "New User" }), :valid?
      assert_predicate(
        RowValidator.new({ "email_address" => "new@example.com", "full_name" => "New User", "role" => "" }), :valid?
      )
    end

    test "role set to admin or default is valid" do
      %w[admin default].each do |role|
        row = RowValidator.new({ "email_address" => "new@example.com", "full_name" => "New User", "role" => role })

        assert_predicate row, :valid?
      end
    end

    test "an invalid role value is invalid" do
      row = RowValidator.new(
        { "email_address" => "new@example.com", "full_name" => "New User", "role" => "superadmin" }
      )

      assert_not row.valid?
      assert_includes row.errors, "role is invalid"
    end
  end
end
