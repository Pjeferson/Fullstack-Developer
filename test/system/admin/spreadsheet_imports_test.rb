require "application_system_test_case"

class Admin::SpreadsheetImportsTest < ApplicationSystemTestCase
  test "uploading a spreadsheet shows live progress, then the history reflects it on close" do
    sign_in_as(users(:admin))
    visit admin_spreadsheet_imports_path

    perform_enqueued_jobs do
      attach_file "file", Rails.root.join("test/fixtures/files/imports/valid.csv")
      click_button "Upload"

      # The progress modal opens automatically right after a fresh upload (never from clicking a
      # history row - see chore/quality-hardening) and reaches "Completed" via a real Action
      # Cable broadcast, not a poll or a page reload.
      within "[role=dialog]" do
        assert_text "valid.csv"
        assert_text "Completed"
      end
    end

    assert_equal 1, SpreadsheetImport.count
    assert_equal 2, User.where(email_address: %w[alice@example.com bob@example.com]).count

    find("[role=dialog] button[aria-label=Close]").click
    assert_no_selector "[role=dialog]"

    # Closing reloads the history from the server (reset: ['imports']) - the row for the import
    # we just watched complete reflects that without a manual page refresh.
    within "table" do
      assert_text "valid.csv"
      assert_text "Completed"
    end
  end

  test "uploading an unsupported file type is rejected client-side, nothing is created" do
    sign_in_as(users(:admin))
    visit admin_spreadsheet_imports_path

    assert_no_difference "SpreadsheetImport.count" do
      attach_file "file", Rails.root.join("test/fixtures/files/not_an_image.txt")
      click_button "Upload"
      assert_text "must be a CSV or XLSX file"
    end
    assert_no_selector "[role=dialog]"
  end
end
