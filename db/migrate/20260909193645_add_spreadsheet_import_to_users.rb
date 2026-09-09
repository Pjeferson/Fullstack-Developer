class AddSpreadsheetImportToUsers < ActiveRecord::Migration[8.1]
  def change
    # Nullable - most Users (invited, or future self-registered) never had an originating
    # import. No backfill: existing rows simply get NULL, which is the correct value for them.
    add_reference :users, :spreadsheet_import, foreign_key: true
  end
end
