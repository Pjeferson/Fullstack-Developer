# Processes an uploaded spreadsheet in batches, so a large file never blocks the upload
# request and never loads more than one batch of rows into memory at once. Checkpoints
# last_completed_batch after each batch so a retry (worker restart, dropped DB connection)
# resumes instead of restarting from row zero or duplicating Users — see design.md.
class SpreadsheetImportJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 500

  discard_on ActiveRecord::RecordNotFound

  discard_on Imports::UnsupportedFormatError do |job, _error|
    SpreadsheetImport.find_by(id: job.arguments.first)&.update!(status: :failed, finished_at: Time.current)
  end

  retry_on ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad, wait: :polynomially_longer, attempts: 5

  def perform(spreadsheet_import_id)
    import = SpreadsheetImport.find(spreadsheet_import_id)

    import.file.open do |tempfile|
      parser = Imports::ParserFactory.for(
        content_type: import.file.content_type,
        filename: import.file.filename.to_s,
        path: tempfile.path
      )

      import.update!(status: :processing, total_rows: parser.row_count, started_at: import.started_at || Time.current)

      process_batches(import, parser)
    end

    import.update!(status: :completed, finished_at: Time.current)
  rescue Imports::UnsupportedFormatError, ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad
    raise # handled by discard_on/retry_on above — don't mask with our own status update
  rescue StandardError
    import&.update!(status: :failed, finished_at: Time.current)
    raise
  end

  private
    # A method (not a bare constant reference) so tests can stub a small batch size instead of
    # needing 500+ fixture rows to exercise multi-batch/resume behavior.
    def batch_size
      BATCH_SIZE
    end

    def process_batches(import, parser)
      parser.each_row.each_slice(batch_size).each_with_index do |rows, batch_index|
        next if batch_index < import.last_completed_batch # already inserted on a prior attempt

        result = Imports::UserBatchInserter.new(rows).call
        enqueue_avatar_jobs(result.inserted, rows)

        import.update!(
          processed_rows: import.processed_rows + rows.size,
          success_count: import.success_count + result.inserted_count,
          error_count: import.error_count + result.failed_rows.size,
          last_completed_batch: batch_index + 1
        )
      end
    end

    # One AttachRemoteAvatarJob per successfully-inserted row that has an avatar URL — using
    # the id insert_all's `returning:` gave back, so a duplicate row discarded by ON CONFLICT
    # never triggers a wasted download, and one row's slow/broken avatar never blocks this job.
    def enqueue_avatar_jobs(inserted, rows)
      rows_by_email = rows.index_by { |row| row["email_address"].to_s.strip.downcase }

      inserted.each do |row|
        avatar_url = rows_by_email[row[:email_address]]&.[]("avatar_url").presence
        AttachRemoteAvatarJob.perform_later(row[:id], avatar_url) if avatar_url
      end
    end
end
