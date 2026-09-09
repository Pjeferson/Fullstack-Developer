class SpreadsheetImport < ApplicationRecord
  belongs_to :admin, class_name: "User"
  has_one_attached :file, dependent: :purge_later

  enum :status, { pending: "pending", processing: "processing", completed: "completed", failed: "failed" },
    default: :pending
end
