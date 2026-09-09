require "test_helper"

class Admin::SpreadsheetImportsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @admin = users(:admin)
    @user = users(:one)
  end

  test "guest is redirected to sign in" do
    get admin_spreadsheet_imports_path
    assert_redirected_to new_session_path
  end

  test "non-admin is redirected to root" do
    sign_in_as(@user)
    get admin_spreadsheet_imports_path
    assert_redirected_to root_path
  end

  test "admin can list past imports" do
    sign_in_as(@admin)
    import = SpreadsheetImport.create!(admin: @admin, status: :completed, total_rows: 2, processed_rows: 2, success_count: 2)
    import.file.attach(io: StringIO.new("a,b"), filename: "people.csv", content_type: "text/csv")

    get admin_spreadsheet_imports_path

    assert_response :success
    assert_inertia_component "admin/spreadsheet_imports/index"
    assert_inertia_props do |props|
      row = props[:imports].find { |i| i[:id] == import.id }
      row[:status] == "completed" && row[:filename] == "people.csv" && row[:created_at].present?
    end
  end

  test "requesting a second page via before_id returns the next batch, not the same one" do
    31.times { SpreadsheetImport.create!(admin: @admin) }

    sign_in_as(@admin)
    get admin_spreadsheet_imports_path
    first_page_ids = inertia.props[:imports].map { |i| i[:id] }
    before_id = first_page_ids.last

    get admin_spreadsheet_imports_path, params: { before_id: before_id }
    second_page_ids = inertia.props[:imports].map { |i| i[:id] }

    assert_equal 25, first_page_ids.size
    assert_empty first_page_ids & second_page_ids
    assert second_page_ids.all? { |id| id < before_id }
  end

  test "a valid CSV upload redirects to the imports page and enqueues the job" do
    sign_in_as(@admin)

    assert_difference "SpreadsheetImport.count", 1 do
      assert_enqueued_with(job: SpreadsheetImportJob) do
        post admin_spreadsheet_imports_path, params: { file: fixture_file_upload("imports/valid.csv", "text/csv") }
      end
    end

    import = SpreadsheetImport.last
    assert_redirected_to admin_spreadsheet_imports_path
    assert_equal @admin, import.admin
    assert import.file.attached?
  end

  test "an unsupported file type is rejected and no import is created" do
    sign_in_as(@admin)

    assert_no_difference "SpreadsheetImport.count" do
      assert_no_enqueued_jobs(only: SpreadsheetImportJob) do
        post admin_spreadsheet_imports_path, params: { file: fixture_file_upload("not_an_image.txt", "text/plain") }
      end
    end

    assert_redirected_to admin_spreadsheet_imports_path
  end

  test "a missing file is rejected" do
    sign_in_as(@admin)

    assert_no_difference "SpreadsheetImport.count" do
      post admin_spreadsheet_imports_path, params: {}
    end

    assert_redirected_to admin_spreadsheet_imports_path
  end
end
