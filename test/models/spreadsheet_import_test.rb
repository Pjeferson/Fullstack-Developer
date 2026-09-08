require "test_helper"

class SpreadsheetImportTest < ActiveSupport::TestCase
  test "defaults to pending status" do
    import = SpreadsheetImport.create!(admin: users(:admin))

    assert_predicate import, :pending?
  end

  test "belongs to an admin" do
    import = SpreadsheetImport.create!(admin: users(:admin))

    assert_equal users(:admin), import.admin
  end
end
