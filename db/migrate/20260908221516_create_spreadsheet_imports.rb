class CreateSpreadsheetImports < ActiveRecord::Migration[8.1]
  def change
    create_table :spreadsheet_imports do |t|
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.integer :total_rows
      t.integer :processed_rows, null: false, default: 0
      t.integer :success_count, null: false, default: 0
      t.integer :error_count, null: false, default: 0
      t.integer :last_completed_batch, null: false, default: 0
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end
  end
end
