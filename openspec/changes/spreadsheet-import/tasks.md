## 1. Dependencies and persisted state

- [ ] 1.1 Add `gem "csv"` and `gem "roo"` to the Gemfile, `bundle install`, and verify
  `bin/rails runner 'require "csv"; require "roo"; puts "ok"'` prints `ok`
- [ ] 1.2 Add the `CreateSpreadsheetImports` migration (`admin` FK to `users`, `status`,
  `total_rows`, `processed_rows`, `success_count`, `error_count`, `last_completed_batch`,
  `started_at`, `finished_at` — no per-row error detail, only aggregate counts; see design.md)
  and run `bin/rails db:migrate` and `db:test:prepare`
- [ ] 1.3 Add `app/models/spreadsheet_import.rb` (`belongs_to :admin, class_name: "User"`,
  `enum :status, { pending: "pending", processing: "processing", completed: "completed",
  failed: "failed" }, default: :pending`) and a `test/models/spreadsheet_import_test.rb`
  covering the default status and the `admin` association

## 2. Parser layer (CSV and XLSX behind one interface)

- [ ] 2.1 Add `app/services/imports/parser.rb` (shared `each_row`/`row_count` interface) and
  `app/services/imports/unsupported_format_error.rb`
- [ ] 2.2 Add `app/services/imports/csv_parser.rb` and fixture files (a valid small CSV, one
  with a malformed/short row, one header-only/empty file); add
  `test/services/imports/csv_parser_test.rb` covering `each_row` (with and without a block —
  the no-block case must return an `Enumerator`) and `row_count` against those fixtures
- [ ] 2.3 Add `app/services/imports/xlsx_parser.rb` and equivalent XLSX fixtures; add
  `test/services/imports/xlsx_parser_test.rb` mirroring 2.2's coverage, and assert its output
  hashes have the exact same shape as `CsvParser`'s for equivalent content
- [ ] 2.4 Add `app/services/imports/parser_factory.rb` (content-type match with filename-
  extension fallback, raises `Imports::UnsupportedFormatError` otherwise) and
  `test/services/imports/parser_factory_test.rb` covering CSV, XLSX, and the unsupported case

## 3. Row validation and batch user insertion

- [ ] 3.1 Add `app/services/imports/row_validator.rb` (`new(row).valid?`/`#errors` — checks
  email format, full_name presence, and `role` membership in `User.roles.keys` when present;
  see design.md) and `test/services/imports/row_validator_test.rb` covering: a fully valid row;
  a blank/malformed email; a blank full_name; a blank/missing `role` (valid); `role` set to
  `admin`/`default` (valid); an invalid `role` value (e.g. `superadmin`)
- [ ] 3.2 Add `app/services/imports/user_batch_inserter.rb` (`new(rows).call` — partitions rows
  via `Imports::RowValidator` first, generates one bcrypt digest per batch for the rows that
  passed, resolves `role` via `User.roles.fetch(role, "default")`, then `insert_all` with
  `returning:` and `unique_by: :index_users_on_email_address`; see design.md) returning
  inserted rows plus every rejected row (both `RowValidator` failures and `insert_all`
  duplicates) with a reason
- [ ] 3.3 Add `test/services/imports/user_batch_inserter_test.rb` covering: all-valid batch
  inserts every row; a batch containing a duplicate of an existing User's email inserts the
  others and reports that one as a duplicate failure; a batch containing a row that fails
  `RowValidator` reports it with that reason and does not reach `insert_all`; a row with `role`
  set to `admin` creates that User as `admin`; a row with no `role` column creates a `default`
  User; asserts only one `BCrypt::Password.create` call happens per batch (via `Object#stub`),
  not once per row

## 4. Import job with resume

- [ ] 4.1 Add `app/jobs/spreadsheet_import_job.rb` (finds the `SpreadsheetImport`, resolves the
  parser via `Imports::ParserFactory`, sets `total_rows`/`status: :processing`, iterates
  `each_row.each_slice(BATCH_SIZE)` skipping batches below `last_completed_batch`, calls
  `Imports::UserBatchInserter`, updates counts and the checkpoint after each batch, enqueues
  `AttachRemoteAvatarJob` per successfully-inserted row that has an avatar URL, and sets
  `status: :completed`/`:failed` at the end); `discard_on Imports::UnsupportedFormatError`
- [ ] 4.2 Add `test/jobs/spreadsheet_import_job_test.rb` covering: a full run against a small
  fixture file creates the expected Users and marks the import `completed` with correct counts;
  a run that raises partway through (stub the inserter to raise on the 2nd batch) leaves
  `last_completed_batch` at the batches actually completed and marks the import `failed`; a
  second run of the same import after that failure resumes from `last_completed_batch` and does
  not create duplicate Users for rows already inserted; a row with an avatar URL enqueues
  `AttachRemoteAvatarJob` with the newly-created User's id (`assert_enqueued_with`); a
  duplicate-email row's avatar URL is never enqueued

## 5. Routing, authorization, and controller

- [ ] 5.1 Add `resources :spreadsheet_imports, only: %i[new create show]` under the existing
  `namespace :admin do ... end` in `config/routes.rb` (inherits `Admin::BaseController`'s
  `require_admin`, same as the existing admin routes)
- [ ] 5.2 Add `app/controllers/admin/spreadsheet_imports_controller.rb` (`new` renders the
  upload form; `create` validates the uploaded file's presence/content-type up front, creates
  the `SpreadsheetImport` record with `admin: Current.user` and the file attached, enqueues
  `SpreadsheetImportJob`, and redirects to `show`; `show` renders the persisted import state as
  a prop) and `test/controllers/admin/spreadsheet_imports_controller_test.rb` covering: guest
  and non-admin blocked exactly like the existing admin controller tests; a valid CSV upload
  redirects to `show` and enqueues the job (`assert_enqueued_with`); an unsupported file type is
  rejected with a validation error and no job enqueued; `show` renders the import's current
  persisted counts for its owning admin

## 6. Frontend

- [ ] 6.1 Add `app/javascript/pages/admin/spreadsheet_imports/new.tsx` (file input, submit via
  `useForm`/`post` as `multipart/form-data`, backend errors surfaced the existing
  `errors.<field>` way) using `AdminLayout`
- [ ] 6.2 Add `app/javascript/pages/admin/spreadsheet_imports/show.tsx` (renders the import's
  persisted status and counts — processed/success/error — from Inertia props; no per-row detail
  is shown, only totals; a "Refresh" affordance is enough since this branch has no live updates
  — see design.md's Non-Goals) using `AdminLayout`
- [ ] 6.3 Add a "Import users" link from `AdminLayout` (or the users index) to
  `/admin/spreadsheet_imports/new`, and confirm `npm run check` is clean

## 7. Full verification

- [ ] 7.1 Run `bin/rails test` (full suite green), `bin/rubocop`, and `bin/brakeman` with no new
  offenses
- [ ] 7.2 Manual smoke test via a running `bin/rails server`: sign in as the admin fixture,
  upload a small CSV with a mix of a valid row, a duplicate-email row, and an invalid row, and
  confirm the resulting counts on the `show` page match; repeat with an XLSX file
