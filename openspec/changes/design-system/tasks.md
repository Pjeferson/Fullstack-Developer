## 1. Dependencies

- [x] 1.1 Add `lucide-react` and `@headlessui/react` to `package.json`; confirm `npm run check`
  still passes with no other changes

## 2. Design tokens

- [x] 2.1 Add an `@theme` block to `app/javascript/entrypoints/application.css` aliasing
  `--color-primary`/`--color-primary-hover`/`--color-success`/`--color-warning`/
  `--color-danger`/`--color-surface`/`--color-background`/`--color-border`/`--color-text`/
  `--color-text-muted` to Tailwind's existing indigo/slate/emerald/amber/red scale, and
  `--text-h1`/`--text-h2`/`--text-h3` per the mockup's type scale; confirm the app still builds
  and renders unchanged (tokens defined but not yet consumed anywhere)

## 3. Base UI component library

- [ ] 3.1 Add `components/ui/Button.tsx`, `Input.tsx`, `Select.tsx` (Headless UI `Listbox`-based)
- [ ] 3.2 Add `components/ui/Badge.tsx` (variant-based: default/success/warning/danger/purple),
  `Card.tsx`, `Progress.tsx`
- [ ] 3.3 Add `components/ui/Avatar.tsx` (image with initials fallback when no `avatar_url`) and
  `components/ui/Table.tsx` (shared table shell: header row + body slot)
- [ ] 3.4 Add `components/ui/Modal.tsx` on Headless UI `Dialog` (focus trap, ESC-to-close,
  `w-full sm:max-w-md sm:mx-auto` responsive sizing per design.md)
- [ ] 3.5 Confirm `npm run check` is clean (components exist and typecheck, not yet consumed by
  any page)

## 4. Responsive app shell

- [ ] 4.1 Add `components/layout/Sidebar.tsx` (fixed `md:flex md:w-64` and up; nav items: Users,
  Imports, My profile, Sign out — no separate "Dashboard" item, since `/admin/users` already is
  the dashboard) and `components/layout/Topbar.tsx` (current-user avatar/email, mobile menu
  button)
- [ ] 4.2 Add `components/layout/AppShell.tsx` wiring `Sidebar` + `Topbar`, with the sidebar
  opening as a Headless UI `Dialog` drawer below `md` on the menu button
- [ ] 4.3 Delete `app/javascript/layouts/AdminLayout.tsx`; update `admin/users/index.tsx` and
  `admin/spreadsheet_imports/*.tsx`'s `.layout` assignment to `AppShell` (existing page content
  unchanged for now — this task only swaps the shell)
- [ ] 4.4 Confirm `npm run check` is clean and the app still renders (existing pages, new shell)

## 5. Associate Users with their originating spreadsheet import

- [ ] 5.1 Add migration `add_reference :users, :spreadsheet_import, foreign_key: true` (nullable)
  and run `bin/rails db:migrate`
- [ ] 5.2 Add `belongs_to :spreadsheet_import, optional: true` to `User`, `has_many :users` to
  `SpreadsheetImport`; extend `test/models/user_test.rb` with the association test
- [ ] 5.3 Change `Imports::UserBatchInserter.new(rows)` to `.new(rows, import:)`, add
  `spreadsheet_import_id: import.id` to `attributes_for`'s `insert_all` payload; update
  `SpreadsheetImportJob#process_batches` to pass `import:`; update
  `test/services/imports/user_batch_inserter_test.rb` (assert `spreadsheet_import_id` set on
  every inserted row) and `test/jobs/spreadsheet_import_job_test.rb` for the new call signature
- [ ] 5.4 Run `bin/rails test` — full suite green

## 6. Spreadsheet imports listing

- [ ] 6.1 Add `app/queries/admin/spreadsheet_imports_query.rb` mirroring
  `app/queries/admin/users_query.rb` (cursor `before_id`, `PER_PAGE = 25`,
  `.with_attached_file` to avoid the filename N+1) and
  `test/queries/admin/spreadsheet_imports_query_test.rb` mirroring
  `test/queries/admin/users_query_test.rb`'s cases
- [ ] 6.2 Add `Admin::SpreadsheetImportsController#index` (query + `imports_json` layering
  `filename`/`created_at` over `summary_json`, `InertiaRails.scroll`); remove `#new`/`#show`;
  update `config/routes.rb` to `resources :spreadsheet_imports, only: %i[index create]`
- [ ] 6.3 Update `test/controllers/admin/spreadsheet_imports_controller_test.rb`: remove
  `new`/`show` cases, add `index` (pagination shape, N+1 guard), update the `create` success
  case's redirect assertion to the imports index instead of `show`
- [ ] 6.4 Run `bin/rails test` — full suite green

## 7. Rebuild the admin Users page

- [ ] 7.1 Add `components/users/UserStats.tsx` (from `components/admin/DashboardStats.tsx`),
  `RoleBadge.tsx` (moved, now a thin `ui/Badge` wrapper)
- [ ] 7.2 Add `components/users/UserRow.tsx` and `UserCard.tsx` (table row / mobile card, same
  props, from `components/admin/UserRow.tsx`), `UserTable.tsx` (renders both, toggled via
  `hidden md:table` / `md:hidden`)
- [ ] 7.3 Add `components/users/UserForm.tsx` (fields shared by create/edit, from
  `pages/admin/users/{new,edit}.tsx`) and `UserModal.tsx` (wraps `UserForm` in `ui/Modal` for
  both create and edit modes; edit mode seeds from the row's already-loaded data)
- [ ] 7.4 Add `components/users/DeleteUserDialog.tsx` (confirmation dialog on `ui/Modal`,
  replacing the native `confirm()` in the old `UserRow`)
- [ ] 7.5 Rewrite `pages/admin/users/index.tsx`: render `UserStats`, `UserTable` (wrapped in the
  existing `InfiniteScroll`), and the create/edit/delete modals as local state, not routes
- [ ] 7.6 Remove `Admin::UsersController#new`/`#edit`; make `#create`/`#update` always
  `redirect_to admin_users_path` (success or failure); update `config/routes.rb` to
  `resources :users, only: %i[index create update destroy]`
- [ ] 7.7 Delete `pages/admin/users/{new,edit}.tsx` and
  `components/admin/{DashboardStats,UsersTable,UserRow}.tsx`
- [ ] 7.8 Update `test/controllers/admin/users_controller_test.rb`: remove `new`/`edit` cases,
  update create/update failure-path assertions to redirect to the index (not a dedicated
  new/edit path)
- [ ] 7.9 Run `bin/rails test` and `npm run check` — both clean

## 8. Rebuild the admin Imports page

- [ ] 8.1 Add `components/imports/ImportStatusBadge.tsx` (thin `ui/Badge` wrapper) and
  `ImportUploader.tsx` (upload form, from `pages/admin/spreadsheet_imports/new.tsx`)
- [ ] 8.2 Add `components/imports/ImportRow.tsx` and `ImportCard.tsx` (table row / mobile card)
  and `ImportHistoryTable.tsx` (renders both, same `hidden md:table`/`md:hidden` pattern as
  `UserTable`)
- [ ] 8.3 Add `components/imports/ImportProgressModal.tsx` (progress bar + counts, from
  `pages/admin/spreadsheet_imports/show.tsx`, on `ui/Modal`, subscribing via the existing
  `useImportProgress` hook)
- [ ] 8.4 Add `pages/admin/spreadsheet_imports/index.tsx`: `ImportUploader` + `ImportHistoryTable`
  wrapped in `InfiniteScroll`; opens `ImportProgressModal` from a history row's data, or from
  `imports.data[0]` in the upload form's `onSuccess` (see design.md)
- [ ] 8.5 Delete `pages/admin/spreadsheet_imports/{new,show}.tsx`
- [ ] 8.6 Run `bin/rails test` and `npm run check` — both clean

## 9. Final verification

- [ ] 9.1 Run `bin/rubocop` and `bin/brakeman` — no new offenses
- [ ] 9.2 Manual multi-viewport smoke test via the `run` skill: resize desktop → tablet → mobile
  confirming sidebar→drawer, table→card, and modal-width behavior; create a User via modal
  (success and a forced validation error, confirming the modal stays open with errors); edit and
  delete a User via modal; run a spreadsheet import, confirm it appears in the history and its
  progress modal opens and live-updates; verify (console/db) that an imported User's
  `spreadsheet_import_id` is set
