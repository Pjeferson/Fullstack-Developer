## Why

Admins currently create Users one at a time through the invite form. Onboarding a batch of
Users (a class roster, a new department) means repeating that form by hand for every row. A
bulk import lets an admin upload a spreadsheet and have every row become a User, without
blocking the request while a large file is processed.

## What Changes

- New admin-only spreadsheet import: upload a CSV or XLSX file, each row becomes a User.
- Processing runs asynchronously on Solid Queue — the upload request returns immediately.
- Import progress (rows processed, succeeded, failed) is persisted on a `SpreadsheetImport`
  record, readable via a normal Inertia page load. This branch does not add a live-updating
  progress bar — that is `feature/import-progress`'s job (a separate, later branch per the
  project roadmap), which broadcasts updates over Solid Cable using the state this branch
  persists. This mirrors how the existing avatar-URL upload persists `avatar_processing`
  without any live UI for it.
- A row whose email address already belongs to an existing User is recorded as a per-row
  failure and does not modify the existing User (no upsert).
- Imported Users get a random, unusable password (same semantics as the existing admin invite
  flow) and go through the standard "forgot password" flow to set their own — but **no invite
  email is sent automatically** by the import itself, to avoid bursting the mail provider on a
  large file.
- A row may optionally include an avatar URL; on success it is downloaded and attached the same
  way the existing admin avatar-by-URL flow does (async job, SSRF-filtered, content-type/size
  checked) — a row never sets an avatar by direct file upload (only a URL, since the import
  itself is a single file upload, not one per row).
- A row MAY optionally set the imported User's initial `role` (`default` or `admin`) via a
  `role` column — a deliberate, narrow exception to the single-user invite/edit rule, so
  imported/seed data can include admins for later exercising the live-dashboard-by-role feature
  (a separate, later branch). A `role` value that isn't `default`/`admin` is a per-row failure,
  never a silent fallback. This narrows `admin-user-management`'s existing "role only changes
  through the dedicated role action" rule — see Modified Capabilities below.
- If the import job is interrupted (worker restart, transient DB error), retrying it resumes
  from the last completed batch instead of re-processing the whole file or duplicating Users.

## Capabilities

### New Capabilities
- `spreadsheet-import`: lets an admin upload a CSV/XLSX file of Users, processed asynchronously
  with persisted, resumable progress; covers the upload, the per-row outcome rules (duplicate
  emails, invalid rows, optional avatar URL), and the no-live-broadcast/no-invite-email scope
  boundaries called out above.

### Modified Capabilities
- `admin-user-management`: the "Toggle a User's role" requirement's "role SHALL NOT be
  changeable through any other action" clause gains an explicit exception for the
  spreadsheet-import capability — a User's initial role may now also be set at creation time by
  an imported row's `role` column, not only through the dedicated role-toggle action. The
  single-user invite and edit actions are unaffected — they still never accept `role`.

## Impact

- New tables: `spreadsheet_imports` (state/progress; no queryable per-row detail beyond an
  error list — no new table per row).
- New gems: `csv` (Ruby 4.0 needs it declared explicitly — no longer a Ruby default gem), `roo`
  (XLSX parsing).
- New job: `SpreadsheetImportJob`, queued on Solid Queue, reusing the existing
  `AttachRemoteAvatarJob` for per-row avatars.
- New services under `app/services/imports/`: a shared CSV/XLSX parser interface, and a batch
  user-insertion step.
- New admin-only routes/controller/pages for uploading a file and viewing an import's result.
- No changes to the `User` model's public behavior or schema.
