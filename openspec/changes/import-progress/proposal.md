## Why

`feature/spreadsheet-import` deliberately persisted progress without pushing live updates — an
admin watching the import status page had to hit Refresh to see new counts. This closes that
gap: the status page updates itself in real time while an import is processing, using the
persisted state that branch already maintains as the source of truth.

## What Changes

- The import status page (`/admin/spreadsheet_imports/:id`) now updates its counts and status
  live while an import is processing, over Action Cable (Solid Cable in both development and
  production now — see the development-environment change below).
- **Development now runs the full Solid trifecta** (`solid_cache`, `solid_queue`, `solid_cable`),
  reversing the earlier "development stays lightweight" choice made in `feature/authentication`.
  This branch needs real Action Cable delivery to test against, not just the in-process `async`
  adapter standing in for it. Development gets the same four-Postgres-database shape production
  already uses (`cache`/`queue`/`cable` each their own database) — the conventional, documented
  pattern, not a same-database shortcut; see design.md for two shortcuts that were tried and
  rejected first.
- A `SpreadsheetImportChannel` streams one `SpreadsheetImport`'s updates. Broadcasting (same
  shape already used for the page's initial props) is a dedicated service,
  `Imports::ProgressBroadcaster`, called explicitly by the job right after each `update!` —
  deliberately not a model callback, so persistence and the side effect of pushing a WebSocket
  message stay visibly separate instead of one silently implying the other; see design.md.
- Adds a small reusable `useChannel` frontend hook wrapping Action Cable subscription lifecycle
  (connect on mount, disconnect on unmount) — this is the app's first real-time feature, and
  `feature/dashboard-realtime` (parallel, independent) will need the same plumbing.
- On receiving a broadcast, the page applies the payload directly to local state — `summary_json`
  is the one serialization used both for the page's initial props and every broadcast, so there's
  no drift risk in trusting it directly, and no reason to pay for a round-trip back to the server
  per update. A full Inertia reload (the existing manual "Refresh" button) still works as a
  fallback and re-syncs the same local state.
- Only an authenticated admin may subscribe to an import's channel — mirrors the existing `show`
  action's authorization (any admin, not only the one who started the import).
- Adds a visible progress bar (percentage of `processed_rows`/`total_rows`) to the status page,
  not just the existing text counts — the project roadmap names this "progress bar via Solid
  Cable" specifically.
- No page but `show` changes. This branch does not add a list of in-progress imports, and does
  not touch the import job's actual processing logic — only how its already-persisted state
  reaches the browser, and what backs the queue/cache/cable adapters in development.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `spreadsheet-import`: the "Import progress is persisted and resumable" requirement's
  "Live updates are a separate capability" scenario is replaced — live updates while the page
  is open are now part of this capability, layered on top of the same persisted state (which
  remains the source of truth on page load/refresh, unchanged).

## Impact

- New gem: none on the backend (Action Cable ships with Rails; `solid_cache`/`solid_queue`/
  `solid_cable` are already in the Gemfile from project setup, just not wired into development
  until now). New frontend dependency: `@rails/actioncable`.
- New: `app/channels/spreadsheet_import_channel.rb`, `app/services/imports/
  progress_broadcaster.rb`, `app/javascript/hooks/useChannel.ts`.
- Changed: `app/jobs/spreadsheet_import_job.rb` (explicit broadcast calls),
  `config/routes.rb` (mount Action Cable), `admin/spreadsheet_imports/show.tsx`
  (subscribe + progress bar), `config/database.yml` (development becomes a multi-database
  config, same shape as production: `primary`/`cache`/`queue`/`cable`, each its own database),
  `config/environments/development.rb` (cache store, job adapter), `config/cable.yml`
  (development adapter), `Procfile.dev` (restores the `jobs` process).
- `SpreadsheetImportJob`'s update sites each gain an explicit broadcast call (see above); its
  batching/checkpointing/resume logic is otherwise unchanged. No changes to `Imports::
  {Parser,CsvParser,XlsxParser,ParserFactory,RowValidator,UserBatchInserter}`, `test`
  environment config, or any application-level database schema (the queue/cache/cable schemas
  already exist from `chore/project-setup`, just newly connected to a development database).
