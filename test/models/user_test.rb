require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "defaults role to default" do
    assert_equal "default", User.new.role
  end

  test "requires full_name" do
    user = User.new(email_address: "new@example.com", password: "password")
    assert_not user.valid?
    assert_includes user.errors[:full_name], "can't be blank"
  end

  test "validates email_address format" do
    user = User.new(full_name: "New User", email_address: "not-an-email", password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "is invalid"
  end

  test "validates email_address uniqueness" do
    user = User.new(full_name: "New User", email_address: users(:one).email_address, password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "spreadsheet_import is optional" do
    user = User.new(full_name: "New User", email_address: "new@example.com", password: "password")
    assert_nil user.spreadsheet_import
    assert user.valid?
  end

  test "can be associated with the spreadsheet import that created it" do
    import = SpreadsheetImport.create!(admin: users(:admin))
    user = User.create!(
      full_name: "Imported User", email_address: "imported@example.com", password: "password", spreadsheet_import: import
    )

    assert_equal import, user.spreadsheet_import
    assert_includes import.users, user
  end
end
