## 1. Solid trifecta in development (four databases, same shape as production)

- [x] 1.1 Add a `development:` multi-database block to `config/database.yml` (`primary`/
  `cache`/`queue`/`cable`, mirroring `production:`'s shape exactly — local database names
  `umanni_development`/`_cache`/`_queue`/`_cable`, same `migrations_paths` as production), run
  `bin/rails db:create` and verify the three new databases exist, then `bin/rails db:schema:
  load:cache db:schema:load:queue db:schema:load:cable` and verify each role's tables landed in
  its own database with no changes to `db/{cache,queue,cable}_schema.rb` (`git status` clean on
  those files)
- [x] 1.2 In `config/environments/development.rb`, set `config.cache_store =
  :solid_cache_store`, `config.active_job.queue_adapter = :solid_queue`, and
  `config.solid_queue.connects_to = { database: { writing: :queue } }` (matching
  `production.rb`); in `config/cable.yml`, change `development:` from `adapter: async` to
  `adapter: solid_cable` with the same `connects_to`/`polling_interval`/`message_retention` as
  `production:`
- [x] 1.3 Restore `jobs: bin/jobs` to `Procfile.dev` and verify `bin/rails runner 'puts
  Rails.cache.class; puts Rails.application.config.active_job.queue_adapter'` reports the Solid
  adapters, and a job enqueued via `bin/rails runner` in development is picked up (verify via a
  `SolidQueue::Job` row rather than `bin/dev`, since this sandbox can't keep `bin/dev`'s full
  Procfile cluster running — see the branch's own verification notes)
- [x] 1.4 Update `openspec/config.yaml`'s `context:` — the "development keeps them lightweight
  ... to avoid needing extra local databases" sentence is now false; replace it with the actual
  setup (same Solid adapters and the same four-database shape as production), so future
  AI-driven artifacts don't plan against a stale assumption

## 2. Mount Action Cable

- [x] 2.1 Add `mount ActionCable.server => "/cable"` to `config/routes.rb` and verify
  `bin/rails routes | grep cable` shows it
- [x] 2.2 Add `test/channels/application_cable/connection_test.rb` covering
  `ApplicationCable::Connection`'s existing (unchanged) `current_user` identification: a request
  with a valid signed session cookie connects and identifies `current_user`; a request with no/
  invalid session cookie is rejected

## 3. Broadcast the import's state explicitly, from the job

- [x] 3.1 Add `SpreadsheetImport#summary_json` (the field list currently duplicated in
  `Admin::SpreadsheetImportsController#import_json`: `id`, `status`, `total_rows`,
  `processed_rows`, `success_count`, `error_count`) — no callback, the model stays persistence +
  serialization only (see design.md for why a callback was tried and rejected); update the
  controller's `show` action to call `@import.summary_json` instead of its own `import_json`,
  removing the now-duplicate private method
- [x] 3.2 Add `app/channels/application_cable/channel.rb` (the base `ApplicationCable::Channel`
  — missing from this app entirely, `connection.rb` existed but never its channel counterpart;
  standard Rails boilerplate) and `app/channels/spreadsheet_import_channel.rb` (`subscribed`
  finds the import by `params[:id]`, rejects unless `current_user&.admin?`, otherwise
  `stream_for import`)
- [x] 3.3 Add `app/services/imports/progress_broadcaster.rb` (`new(import).call` —
  `SpreadsheetImportChannel.broadcast_to(import, import.summary_json)`) and
  `test/services/imports/progress_broadcaster_test.rb` covering it broadcasts the import's
  current `summary_json`
- [x] 3.4 Update `SpreadsheetImportJob`: add a private `update_and_broadcast!(import,
  attributes)` helper (`import.update!(attributes)` then `Imports::ProgressBroadcaster.new(
  import).call`) and use it at all five places the job calls `update!` directly (marking
  processing, each batch, completion, the `rescue StandardError` block, the `discard_on` block —
  corrected from design.md's earlier undercount of "four"); add `test/jobs/
  spreadsheet_import_job_test.rb` coverage asserting the happy path broadcasts once per update
  (`assert_broadcasts`, count 3 for a single-batch file: processing, the batch, completed) and
  that the `discard_on` path broadcasts the failed status too, guarding against a future
  `update!` added without going through the helper
- [x] 3.5 Add `test/channels/spreadsheet_import_channel_test.rb` (`ActionCable::Channel::
  TestCase`) covering: an admin subscribing to an existing import's id is confirmed and streaming
  (`subscription.confirmed?`, `assert_has_stream_for`); a non-admin connection is rejected
  (`subscription.rejected?`); subscribing with a nonexistent import id is rejected
- [x] 3.6 Update `test/controllers/admin/spreadsheet_imports_controller_test.rb`'s `show` test
  if needed so it still passes against `summary_json` (props shape is unchanged, only where the
  method lives)

## 4. Frontend Action Cable plumbing

- [ ] 4.1 Add `@rails/actioncable` to `package.json` (`npm install`) and verify `npm run check`
  stays clean
- [ ] 4.2 Add `app/javascript/hooks/useChannel.ts` — a generic `<T>` hook (cached shared
  consumer; subscribe on mount/params change, unsubscribe on unmount), with a comment on the
  hook itself explaining why a hook (subscription lifecycle tied to mount/unmount — see
  design.md) rather than a plain function

## 5. Live-update the import status page

- [ ] 5.1 Update `app/javascript/pages/admin/spreadsheet_imports/show.tsx` to hold the import
  summary in local state (`useState(initialImport)`), sync it from the `import` prop on change
  (`useEffect`, keeps the existing manual "Refresh" reload working), and apply
  `useChannel<SpreadsheetImportSummary>('SpreadsheetImportChannel', { id: initialImport.id },
  setSpreadsheetImport)` directly — no `router.reload` involved in the live-update path; add a
  visible progress bar (`processed_rows`/`total_rows`, 0% while `total_rows` is `null`)
  alongside the existing counts
- [ ] 5.2 Confirm `npm run check` is clean

## 6. Full verification

- [ ] 6.1 Run `bin/rails test` (full suite green), `bin/rubocop`, and `bin/brakeman` with no new
  offenses
- [ ] 6.2 Manual smoke test via a running `bin/rails server` (with `bin/jobs` also running, now
  that development uses `solid_queue`): sign in as admin, upload a CSV large enough to span a
  couple of batches (stub/lower the batch size the same way the job's own tests do, or use a
  file with enough rows), open the `show` page, and confirm the counts, status, and progress bar
  update on their own — via real `solid_cable` delivery, not the `async` adapter — without a
  manual reload, ending at `completed`
