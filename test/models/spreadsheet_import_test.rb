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

  test "summary_json exposes only status/progress fields" do
    import = SpreadsheetImport.create!(
      admin: users(:admin), status: :processing, total_rows: 10, processed_rows: 4,
      success_count: 3, error_count: 1
    )

    assert_equal(
      {
        "id" => import.id, "status" => "processing", "total_rows" => 10,
        "processed_rows" => 4, "success_count" => 3, "error_count" => 1
      },
      import.summary_json
    )
  end
end
