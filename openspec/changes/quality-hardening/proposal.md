## Why

With Admin, User, and Visitor use cases functionally complete, this is a general cleanup/
hardening pass requested directly by the admin — not new business rules (no capability spec
deltas needed, per `skip_specs: true` on this change), but real quality issues worth closing
before the final submission: unmeasured test coverage, a known N+1 in the admin User list, a
codebase-wide pass on comment quality, a documented (not silently skipped) decision on backend
validation depth, client-side validation that currently doesn't exist at all, and one unused
frontend component.

## What Changes

- Adds SimpleCov and reports the current backend line-coverage percentage — closing any gap is
  explicitly a separate, later effort, not part of this change.
- Fixes the admin User list's avatar N+1: `Admin::UsersQuery` (and, for consistency,
  `Admin::SpreadsheetImportsQuery`) now accept the base scope as a constructor argument instead
  of hardcoding (or omitting) eager-loading internally — the caller decides what to eager-load.
  Regression tests assert the attachment-related query count stays flat regardless of row count.
- Removes comments that only restate the adjacent code; keeps ones that explain a decision,
  trade-off, or non-obvious reason, across `app/` and `app/javascript/`.
- **No backend schema-validation layer added** — a deliberate reversal of an earlier plan,
  confirmed in conversation: validation stays at the model level (Rails strong params +
  `ActiveModel`/`ActiveRecord` validations), documented as a conscious choice in the README
  rather than left unexplained.
- Adds client-side schema validation with Zod — messages appear as a form is filled (on blur),
  and a submit the client can already tell is invalid never reaches the backend. No
  react-hook-form: Inertia's `useForm` stays the one form-state manager; Zod validation layers
  on top of it via a small new `useValidation` hook. Applied to sign-in, registration,
  forgot/reset password, and the shared `UserForm` (admin create/edit + self-service profile,
  which is also de-duplicated onto `UserForm` in the same change instead of hand-rolling its own
  copy of the same two fields).
- Removes `components/ui/Select.tsx` — confirmed unused (0 references anywhere in the app).
- **Added on review**: fixes a real gap noticed while testing the branch — an import's row in
  the admin history table stayed stale after its live-progress modal (watched all the way to
  completion) was closed. Fixed with a local state patch, not a server reload — see design.md's
  "Post-Review Increment" for why a reload was rejected.
- **Added on review**: extends the client-side validation from item 6 to `ImportUploader`'s file
  field — the one required field that item missed, mirroring the same presence/format checks
  `Admin::SpreadsheetImportsController#create` already makes.
- **Added on review**: fixes a real bug the user found testing the item above — the native file
  input kept showing a stale filename after a successful upload (it's uncontrolled; `reset()`
  can't touch it), so a second upload without reselecting a file silently failed. Now cleared via
  a ref alongside `reset()`.
- **Added on review**: the progress modal now only ever opens automatically right after a fresh
  upload, never from clicking a history row (a past import's row already shows everything the
  modal would). This replaces item 8's local-patch-on-close with a plain server reload on close —
  see design.md's last two "Post-Review Increment" sections for why the reload is safe now.
- **Added on review**: two more entries under the README's "Deliberate Implementation Decisions"
  (renamed from "Implementation Decisions") — explaining why broadcasts are called explicitly
  rather than from a model callback, and why this app's JSON is hand-rolled rather than built
  through a serialization gem.
- **Added on review**: closes the coverage gap item 1 explicitly deferred — 3 new tests bring
  backend line coverage to 100% (477/477), each covering a real branch that was previously
  untested rather than padding the number artificially.

Out of scope: closing the coverage gap itself, a JS test runner for the new validation code
(Playwright remains the next branch), and any change to what the backend actually accepts or
rejects (client-side validation mirrors existing backend rules exactly, it doesn't add new ones).

## Capabilities

### New Capabilities
None — internal quality/architecture work, no new or changed user-facing requirement.

### Modified Capabilities
None — `skip_specs: true`; see design.md for the full rationale on each item instead.

## Impact

- **Backend**: `Gemfile`/`test/test_helper.rb` (SimpleCov); `app/queries/admin/
  {users,spreadsheet_imports}_query.rb` and their controllers (N+1 fix); comment removal across
  `app/`; `README.md` (new section).
- **Frontend**: `package.json` (zod); new `app/javascript/schemas/*`,
  `app/javascript/hooks/useValidation.ts`; `pages/{sessions/new,registrations/new,
  passwords/new,passwords/edit,profiles/show}.tsx` and `components/users/UserForm.tsx` updated;
  `components/ui/Select.tsx` deleted; comment removal across `app/javascript/`.
- **Tests**: new N+1 regression tests on the two admin list controller tests. No other test
  behavior changes (frontend validation isn't backend-testable, and doesn't change what the
  backend accepts).
