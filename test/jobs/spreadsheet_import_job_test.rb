require "test_helper"

class SpreadsheetImportJobTest < ActiveJob::TestCase
  FIXTURES = Rails.root.join("test/fixtures/files/imports")

  setup do
    @import = SpreadsheetImport.create!(admin: users(:admin))
    attach_csv(@import, "valid.csv") # alice@example.com, bob@example.com (bob has role: admin)
  end

  test "a full run creates the expected Users and marks the import completed" do
    SpreadsheetImportJob.perform_now(@import.id)
    @import.reload

    assert_predicate @import, :completed?
    assert_equal 2, @import.total_rows
    assert_equal 2, @import.processed_rows
    assert_equal 2, @import.success_count
    assert_equal 0, @import.error_count
    assert User.exists?(email_address: "alice@example.com")
    assert_predicate User.find_by!(email_address: "bob@example.com"), :admin?
  end

  test "a failure partway through leaves the checkpoint at the last completed batch and marks the import failed" do
    with_failing_second_batch do
      job = SpreadsheetImportJob.new(@import.id)
      with_batch_size(job, 1) { assert_raises(RuntimeError) { job.perform_now } }
    end
    @import.reload

    assert_predicate @import, :failed?
    assert_equal 1, @import.last_completed_batch
    assert_equal 1, @import.success_count
    assert User.exists?(email_address: "alice@example.com")
    assert_not User.exists?(email_address: "bob@example.com")
  end

  test "resuming after a failure continues from the checkpoint without duplicating Users" do
    with_failing_second_batch do
      job = SpreadsheetImportJob.new(@import.id)
      with_batch_size(job, 1) { assert_raises(RuntimeError) { job.perform_now } }
    end

    # Retry: a fresh job instance, same import id — this is what Solid Queue's retry_on does.
    retry_job = SpreadsheetImportJob.new(@import.id)
    with_batch_size(retry_job, 1) { retry_job.perform_now }
    @import.reload

    assert_predicate @import, :completed?
    assert_equal 2, @import.success_count
    assert_equal 1, User.where(email_address: "alice@example.com").count
    assert_equal 1, User.where(email_address: "bob@example.com").count
  end

  test "a row with an avatar URL enqueues AttachRemoteAvatarJob for the newly-created User" do
    attach_csv(@import, "with_avatar_url.csv")

    assert_enqueued_with(job: AttachRemoteAvatarJob) do
      SpreadsheetImportJob.perform_now(@import.id)
    end

    user = User.find_by!(email_address: "dana@example.com")
    enqueued = enqueued_jobs.find { |j| j["job_class"] == "AttachRemoteAvatarJob" }
    assert_equal [ user.id, "https://example.com/avatar.png" ], enqueued["arguments"]
  end

  test "a duplicate-email row's avatar URL is never fetched" do
    attach_csv(@import, "duplicate_with_avatar_url.csv")

    assert_no_enqueued_jobs(only: AttachRemoteAvatarJob) do
      SpreadsheetImportJob.perform_now(@import.id)
    end
  end

  private
    def attach_csv(import, filename)
      import.file.attach(
        io: File.open(FIXTURES.join(filename)),
        filename: filename,
        content_type: "text/csv"
      )
    end

    def with_batch_size(job, size)
      job.stub(:batch_size, size) { yield }
    end

    # Makes the batch containing "bob" (the 2nd row/batch, once batch_size is stubbed to 1)
    # raise, while the batch containing "alice" (the 1st) still inserts normally.
    def with_failing_second_batch
      call_count = 0
      original_new = Imports::UserBatchInserter.method(:new)
      failing_new = lambda do |rows|
        call_count += 1
        raise "boom" if call_count == 2
        original_new.call(rows)
      end

      Imports::UserBatchInserter.stub(:new, failing_new) { yield }
    end
end
