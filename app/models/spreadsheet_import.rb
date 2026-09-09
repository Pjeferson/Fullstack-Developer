class SpreadsheetImport < ApplicationRecord
  belongs_to :admin, class_name: "User"
  has_one_attached :file, dependent: :purge_later

  enum :status, { pending: "pending", processing: "processing", completed: "completed", failed: "failed" },
    default: :pending

  # The shape an import is rendered as wherever its progress is shown — the show page's initial
  # props and every SpreadsheetImportChannel broadcast (via Imports::ProgressBroadcaster) both
  # use this, so the two can't drift apart.
  def summary_json
    as_json(only: %i[id status total_rows processed_rows success_count error_count])
  end
end
