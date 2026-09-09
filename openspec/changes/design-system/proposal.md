## Why

The admin area has no shared visual language (each page hand-rolls its own inputs/badges/
buttons) and zero responsive treatment anywhere in the app — confirmed via a diagnostic pass
against the challenge brief: no `sm:`/`md:`/`lg:` class exists in `app/javascript/**/*.tsx`, and
the User table has no small-viewport fallback. Separately, the admin's own review notes flagged
that User create/edit/delete should collapse into modals on the listing instead of full-page
navigations, and that Users created via a spreadsheet import have no traceable origin (no way to
tell which import created a given User, and no way to see past imports at all — only
`new`/`create`/`show` exist for imports today, no listing).

The admin supplied three reference mockups (a design-token/component sheet, a responsive
breakpoint reference, and an import-history screen) establishing the target visual system and
component shape.

## What Changes

- Introduces a shared design token set (color, typography) on top of Tailwind v4's `@theme`
  mechanism, and a reusable `components/ui/*` primitive library (Button, Input, Select, Badge,
  Card, Modal, Avatar, Progress, Table), replacing each page's ad-hoc styling.
- Replaces the top-nav-only `AdminLayout` with a responsive `AppShell` (fixed sidebar on
  tablet/desktop, a slide-over drawer below the `md` breakpoint) used by both admin pages.
- **BREAKING** (internal routes only, no external API): `admin/users/new` and
  `admin/users/edit` pages/actions are removed. Creating, editing, and deleting a User now
  happens via modals on `/admin/users` itself — the admin never navigates away from the list.
- **BREAKING** (internal routes only): `admin/spreadsheet_imports/new` and
  `admin/spreadsheet_imports/show` pages/actions are removed. `/admin/spreadsheet_imports`
  becomes a single page: an upload panel plus a paginated import history list. Viewing an
  import's live progress (via the existing `SpreadsheetImportChannel`) now happens in a modal
  opened from that history, instead of a dedicated page reached by redirect after upload.
- Adds an import-history listing (`Admin::SpreadsheetImportsController#index`,
  `Admin::SpreadsheetImportsQuery`, mirroring `Admin::UsersQuery`'s existing cursor-pagination
  pattern) — this did not exist before in any form.
- Adds a nullable `spreadsheet_import_id` on `users`, set for every User a spreadsheet import
  creates, so a User's origin (invited, imported, or — later — self-registered) is traceable.
  No backfill/data reset needed: existing Users simply get `NULL`.
- Formalizes a destructive-action confirmation dialog (replacing the native `confirm()` used for
  User deletion today) as a shared, reusable `ui/Modal`-based component.

Out of scope for this change: system/Playwright tests (the next branch), the still-missing AI
disclosure section in the README, and Visitor self-registration — all raised in the diagnostic
that prompted this change, but not part of it.

## Capabilities

### New Capabilities
- `design-system`: the shared visual language (design tokens, reusable UI component
  conventions) and the admin area's responsive behavior across desktop/tablet/mobile viewports.

### Modified Capabilities
- `admin-user-management`: the "Invite a User", "Edit a User", and "Delete a User" requirements
  change from full-page-navigation flows to modal-based flows on the User list page; deletion
  gains an explicit confirmation-dialog scenario (previously implemented but never spec'd).
- `spreadsheet-import`: the "Upload a spreadsheet to import Users" requirement's successful-
  upload scenario changes from "redirected to a status page" to "stays on the imports page, a
  progress modal opens"; the existing live-progress requirement's scenarios move from "an
  import's status page" to "an import's progress modal, opened from the import history"; two
  requirements are added — an admin can see a paginated history of past imports, and every User
  a spreadsheet import creates is associated with that import.

## Impact

- **Backend**: `app/models/{user,spreadsheet_import}.rb`; new migration
  (`add_reference :users, :spreadsheet_import`); `app/services/imports/user_batch_inserter.rb`
  (new `import:` argument); `app/jobs/spreadsheet_import_job.rb`; new
  `app/queries/admin/spreadsheet_imports_query.rb`; `app/controllers/admin/{users_controller,
  spreadsheet_imports_controller}.rb` (drop `new`/`edit`/`show`, add `index` to imports);
  `config/routes.rb`.
- **Frontend**: new `components/ui/*`, `components/layout/*`, `components/users/*`,
  `components/imports/*`; `pages/admin/users/index.tsx` rewritten; new
  `pages/admin/spreadsheet_imports/index.tsx`; `pages/admin/users/{new,edit}.tsx`,
  `pages/admin/spreadsheet_imports/{new,show}.tsx`, and `layouts/AdminLayout.tsx` deleted.
- **New dependencies**: `lucide-react` (icon set), `@headlessui/react` (accessible Modal/drawer/
  Select primitives — focus trap, ESC-to-close, ARIA semantics).
- **Tests**: `test/controllers/admin/{users_controller,spreadsheet_imports_controller}_test.rb`
  updated for the removed/added actions; new `test/queries/admin/spreadsheet_imports_query_test.rb`;
  `test/services/imports/user_batch_inserter_test.rb` and
  `test/jobs/spreadsheet_import_job_test.rb` updated for the new `import:` argument;
  `test/models/user_test.rb` gains the new association test. No new frontend automated tests in
  this change (Playwright is the next branch by design) — frontend correctness here is `npm run
  check` plus a manual multi-viewport smoke test.
