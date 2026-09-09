require "test_helper"

class Admin::SpreadsheetImportsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @admin = users(:admin)
    @user = users(:one)
  end

  test "guest is redirected to sign in" do
    get new_admin_spreadsheet_import_path
    assert_redirected_to new_session_path
  end

  test "non-admin is redirected to root" do
    sign_in_as(@user)
    get new_admin_spreadsheet_import_path
    assert_redirected_to root_path
  end

  test "admin can view the upload form" do
    sign_in_as(@admin)
    get new_admin_spreadsheet_import_path
    assert_response :success
    assert_inertia_component "admin/spreadsheet_imports/new"
  end

  test "a valid CSV upload redirects to show and enqueues the job" do
    sign_in_as(@admin)

    assert_difference "SpreadsheetImport.count", 1 do
      assert_enqueued_with(job: SpreadsheetImportJob) do
        post admin_spreadsheet_imports_path, params: { file: fixture_file_upload("imports/valid.csv", "text/csv") }
      end
    end

    import = SpreadsheetImport.last
    assert_redirected_to admin_spreadsheet_import_path(import)
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

    assert_redirected_to new_admin_spreadsheet_import_path
  end

  test "a missing file is rejected" do
    sign_in_as(@admin)

    assert_no_difference "SpreadsheetImport.count" do
      post admin_spreadsheet_imports_path, params: {}
    end

    assert_redirected_to new_admin_spreadsheet_import_path
  end

  test "show renders the import's persisted status and counts" do
    sign_in_as(@admin)
    import = SpreadsheetImport.create!(
      admin: @admin, status: :completed, total_rows: 2, processed_rows: 2, success_count: 1, error_count: 1
    )

    get admin_spreadsheet_import_path(import)

    assert_response :success
    assert_inertia_component "admin/spreadsheet_imports/show"
    assert_inertia_props do |props|
      props[:import][:id] == import.id &&
        props[:import][:status] == "completed" &&
        props[:import][:success_count] == 1 &&
        props[:import][:error_count] == 1
    end
  end
end
