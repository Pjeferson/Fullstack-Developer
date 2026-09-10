## 1. Coverage measurement

- [x] 1.1 Add `gem "simplecov", require: false` to the `:test` group in `Gemfile`;
  `require "simplecov"; SimpleCov.start "rails"` as the first lines of `test/test_helper.rb`
  (before `require_relative "../config/environment"`); confirm `/coverage/` is gitignored
- [x] 1.2 Run `bin/rails test`, report the resulting line-coverage percentage in chat (no attempt
  to close gaps this branch)

## 2. Comment sweep

- [x] 2.1 Sweep `app/` (controllers, models, services, queries, jobs, channels, mailers):
  remove comments that only restate the adjacent code; keep ones explaining a decision,
  trade-off, rejected alternative, or non-obvious constraint
- [x] 2.2 Sweep `app/javascript/` (components, pages, hooks, types) the same way
- [x] 2.3 Run `bin/rails test` and `npm run check` — both clean (no behavior change expected)

## 3. Remove unused component

- [x] 3.1 Delete `app/javascript/components/ui/Select.tsx` (confirmed 0 references)
- [x] 3.2 Run `npm run check` — clean

## 4. Fix admin list N+1s

- [x] 4.1 `Admin::UsersQuery` and `Admin::SpreadsheetImportsQuery`: accept `scope:` in the
  constructor (defaulting to `User.all`/`SpreadsheetImport.all`), use it as the base of `fetched`
  instead of a hardcoded/absent scope
- [x] 4.2 `Admin::UsersController#index` passes `scope: User.with_attached_avatar_image`;
  `Admin::SpreadsheetImportsController#index` passes `scope: SpreadsheetImport.with_attached_file`
  (moved out of the query object, where it was hardcoded)
- [x] 4.3 Add a regression test to each controller test (`admin/users_controller_test.rb`,
  `admin/spreadsheet_imports_controller_test.rb`): create several records with attachments,
  subscribe to `sql.active_record` notifications, assert the attachment-table query count stays
  flat (≈1-2) regardless of row count
- [x] 4.4 Run `bin/rails test` — full suite green

## 5. Document the backend-validation decision

- [x] 5.1 Draft the README section wording, show it for review before applying (same process as
  the AI-disclosure section)
- [x] 5.2 Apply it to `README.md` once approved

## 6. Client-side schema validation (Zod)

- [x] 6.1 Add `zod` to `package.json`
- [x] 6.2 Add `app/javascript/schemas/` (fullName/email/password primitives; `userFormSchema`,
  `registrationSchema`, `sessionSchema`, `passwordsNewSchema`, `passwordsEditSchema` composed
  from them) mirroring backend rules exactly — no invented stricter rules
- [x] 6.3 Add `app/javascript/hooks/useValidation.ts` (`useValidation(schema, data)` →
  `{ errors, isValid, touch, touchAll }`)
- [x] 6.4 Wire into `pages/sessions/new.tsx`, `pages/registrations/new.tsx`,
  `pages/passwords/{new,edit}.tsx`: `onBlur={() => touch('field')}`,
  `error={clientErrors.field ?? errors.field}`, submit handler gains
  `if (!isValid) { touchAll(); return }` before `post`/`put`
- [x] 6.5 Wire the same into `components/users/UserForm.tsx` (touch/errors as props from its
  caller, `UserModal`, which owns the `useValidation` call alongside its existing `useForm`)
- [x] 6.6 Rewrite `pages/profiles/show.tsx` to render `UserForm` instead of its own duplicated
  full-name/email fields, wiring its own `useValidation(userFormSchema, data)` the same way
  `UserModal` does
- [x] 6.7 Run `bin/rails test` and `npm run check` — both clean

## 7. Final verification

- [x] 7.1 Run `bin/rubocop` and `bin/brakeman` — no new offenses
- [x] 7.2 Manual check via a real browser: admin User list with several avatars loads with a
  flat attachment-query count (checked via Rails log); registration/login/password/profile forms
  show inline errors as fields are blurred and block submission until fixed; a server-only error
  (duplicate email) still appears correctly after submitting

## 8. Post-review increment: refresh the import row on modal close

- [x] 8.1 Fix a real gap noticed during review: an import's row in the history table kept
  showing whatever it looked like when the page/list loaded (e.g. "Pending"), even after an
  admin watched it reach "Completed" live inside `ImportProgressModal`, closing the modal left
  the stale row behind
- [x] 8.2 `ImportProgressModal`'s `onClose` now hands back its last-seen `summary`;
  `admin/spreadsheet_imports/index.tsx` mirrors `imports` into local state (same pattern
  `admin/users/index.tsx` already uses for `stats`) and patches just the closed row with it - no
  server round-trip, since `InertiaRails.scroll`'s merge semantics would treat a plain reload of
  `imports` as another page to append (not a replacement) and would also reset the
  infinite-scroll list back to its first page
- [x] 8.3 Verified via a real browser with a Solid Queue worker running: uploaded a CSV, watched
  the modal reach "Completed" live, closed it, confirmed the row read "Completed 2/2"
  immediately with no network request

## 9. Post-review increment: client-side validation on the import upload field

- [x] 9.1 Noticed while reviewing item 6: `ImportUploader`'s file input was the one required
  field in the app that item 6 didn't cover - still relying on native HTML5 `required` plus a
  full round trip to see `"can't be blank"`/`"must be a CSV or XLSX file"` from the server
- [x] 9.2 Added `importUploadSchema` to `app/javascript/schemas/index.ts`, mirroring
  `Admin::SpreadsheetImportsController#create`'s own checks in the same order (presence, then
  `Imports::ParserFactory`'s supported extensions)
- [x] 9.3 Wired `useValidation(importUploadSchema, ...)` into `ImportUploader.tsx`:
  `onBlur={() => touch('file')}`, `clientErrors.file?.[0] ?? errors.file`, submit handler gains
  `if (!isValid) { touchAll(); return }`
- [x] 9.4 `npm run check` and `bin/rails test` both clean; left manual browser verification to
  the user for this increment, per their request

## 10. Post-review increment: fix a stale native file input after a successful upload

- [x] 10.1 Bug found by the user testing item 9: intermittently, uploading appeared to fail
  instantly with `"can't be blank"` and nothing was processed
- [x] 10.2 Root cause: `<input type="file">` is uncontrolled - `reset()` in `onSuccess` only
  clears Inertia's `data.file` state, it can't touch the native input's own value. After a
  successful upload the browser's file picker kept showing the previous filename while
  `data.file` was already `null` again; clicking Upload again without reselecting a file then
  failed immediately on the now-blank `data.file` (item 9's client check catches it before a
  request even goes out, but the underlying state mismatch predates that check)
- [x] 10.3 Added a `ref` to the file input in `ImportUploader.tsx`; `onSuccess` now also sets
  `fileInputRef.current.value = ''` alongside `reset()`, keeping the native picker in sync with
  the form state
- [x] 10.4 `npm run check` and `bin/rails test` both clean

## 11. Post-review increment: restrict the progress modal to fresh uploads, reload on close

- [x] 11.1 Revised in conversation: the progress modal shouldn't open for every history row
  clicked, only automatically when an import starts - a past import's row already shows
  everything the modal would (status, progress, succeeded/failed counts), so there was no real
  use case for opening it after the fact
- [x] 11.2 Removed `onSelect` from `ImportRow`, `ImportCard`, and `ImportHistoryTable` - history
  rows are now read-only; `admin/spreadsheet_imports/index.tsx` only ever sets `selectedImport`
  from `handleUploaded`, right after a fresh upload
- [x] 11.3 This makes item 8's local-patch-on-close approach unnecessary complexity: since the
  modal only ever shows the just-uploaded import (always at the top of the newest-first history),
  closing it can safely reload from the server and land back on page 1 - that's exactly what page
  1 already contains. `handleCloseProgressModal` now calls
  `router.reload({ only: ['imports'], reset: ['imports'] })`; `reset` tells
  `InertiaRails.scroll`/`PropsResolver` to send `imports` back as a plain replacement instead of
  an appended page (confirmed by reading `props_resolver.rb`), so this doesn't duplicate rows.
  `ImportProgressModal`'s `onClose` reverts to a plain `() => void` - it no longer needs to hand
  back its last-seen `summary`
- [x] 11.4 `npm run check` and `bin/rails test` both clean

## 12. Post-review increment: two more entries under Implementation Decisions

- [x] 12.1 Renamed the section from "Implementation Decisions" to "Deliberate Implementation
  Decisions" (the user's own retitling)
- [x] 12.2 Added "Explicit Side Effects Over Model Callbacks" — documents that
  `Imports::ProgressBroadcaster`/`Dashboard::StatsBroadcaster` are called explicitly from the
  job/controller, never from an `after_save`/`after_update_commit` model callback, and why
- [x] 12.3 Added "Simple, Hand-Rolled JSON Over a Serialization Layer" — documents that every
  JSON shape (`User#profile_json`, `SpreadsheetImport#summary_json`, `users_json`, `imports_json`)
  is a plain `as_json`, no serialization gem in use (`jbuilder` sits in the `Gemfile` unused), and
  that a larger app would reach for a dedicated tool instead
- [x] 12.4 Wording drafted and iterated in chat before being applied, same process as every other
  README addition in this project

## 13. Post-review increment: close the coverage gap to 100%

- [x] 13.1 Requested directly by the user, reversing item 1's original scope (report only,
  closing gaps deferred) — now that the number was known (99.16%, 473/477), closed it
- [x] 13.2 Identified the 4 uncovered lines via SimpleCov's `.resultset.json` merged across the
  4 parallel test workers (a single worker's `coverage/index.html` alone undercounts, since
  Minitest's `parallelize` splits tests across processes)
- [x] 13.3 `Admin::UsersController#update`'s `AvatarAssigner` rejection branch — added "a
  rejected avatar upload on update redirects back with an error" to
  `admin/users_controller_test.rb`, mirroring the equivalent test already covering
  `ProfilesController#update`
- [x] 13.4 `AttachRemoteAvatarJob`'s `rescue Net::OpenTimeout, Net::ReadTimeout; raise` line —
  added "a network timeout is retried instead of recorded as a permanent error", asserting the
  job re-enqueues via `retry_on` instead of falling into the permanent-error `rescue StandardError`
- [x] 13.5 `Imports::Parser`'s two `raise NotImplementedError` contract methods — added
  `test/services/imports/parser_test.rb` with a minimal class that includes the module without
  overriding either method
- [x] 13.6 `bin/rails test` — 159 runs, 100.00% line coverage (477/477); `bin/rubocop`/
  `bin/brakeman` clean
