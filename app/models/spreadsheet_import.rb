class SpreadsheetImport < ApplicationRecord
  belongs_to :admin, class_name: "User"

  enum :status, { pending: "pending", processing: "processing", completed: "completed", failed: "failed" },
    default: :pending
end
