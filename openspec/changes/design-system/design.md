## Context

See proposal.md for motivation. Relevant existing state:

- **Tailwind v4, not v3.** `app/javascript/entrypoints/application.css` is `@import
  'tailwindcss'` plus `@plugin` directives for `@tailwindcss/forms`/`@tailwindcss/typography` —
  there is no `tailwind.config.js` anywhere in the repo. Tokens in v4 are CSS custom properties
  inside an `@theme` block in that same file, not a JS config object.
- **No icon library, no accessible-dialog primitive.** `package.json` has neither today; every
  existing "modal-like" interaction (User deletion) uses the native `confirm()`.
- **`Admin::UsersQuery`** (`app/queries/admin/users_query.rb`) already establishes the
  cursor-pagination pattern this change extends to imports: fetch `PER_PAGE + 1` rows, slice to
  detect a next page, no `COUNT(*)`. `InertiaRails.scroll` + `<InfiniteScroll>` are already wired
  for `admin/users`.
- **`admin/spreadsheet_imports` has no `index` action at all** — only `new`/`create`/`show`
  exist. `Admin::SpreadsheetImportsController#create` redirects to `show`, whose page subscribes
  to `SpreadsheetImportChannel` via the existing `useImportProgress` hook.
- **`Imports::UserBatchInserter`** takes only `rows` today and inserts Users via `insert_all` —
  it has no reference to the `SpreadsheetImport` that's processing them.
- **`profile_json`** (on `User`) already carries every field the old `edit.tsx` needed
  (`email_address`, `full_name`, `role`, `avatar_url`, `avatar_processing`, `avatar_error`) —
  this is what makes dropping a separate `edit` fetch possible (see Decisions).

The three reference mockups (design-token sheet, responsive breakpoints, import screen)
established the target look; the "processing steps" (parse/validate/save/finalize) shown in the
import mockup are **not** being adopted as new persisted state — only `status`/`processed_rows`/
`success_count`/`error_count` are persisted today, and this change doesn't add per-step tracking
just to match a mockup that was a styling reference, not a new data requirement.

## Goals / Non-Goals

**Goals:**
- One design-token source (`@theme`) and one `components/ui/*` primitive set, used consistently
  across the admin area instead of each page hand-rolling styles.
- A responsive `AppShell` (sidebar → drawer, table → card list) that keeps the admin area usable
  from mobile through desktop.
- User create/edit/delete become modal flows on `/admin/users`; no separate `new`/`edit` pages.
- An import-history listing (new), and a live-progress modal (replacing the dedicated `show`
  page) opened from that history.
- Every User a spreadsheet import creates is traceable to that import via a nullable FK.

**Non-Goals:**
- Any change to `admin-dashboard`'s stats/pagination behavior — `/admin/users` stays the same
  page conceptually, only its visual shell and CRUD affordances change.
- Persisting the mockup's per-row processing-step detail (parse/validate/save/finalize) — not
  data this app tracks today, and not requested independent of the mockup.
- Surfacing the new User↔import association anywhere in the UI (e.g. a "via import #N" tag on a
  User row) — the association is captured for traceability; displaying it is a natural follow-up
  but wasn't asked for here.
- Playwright/system tests (explicitly the next branch), the missing README AI-disclosure
  section, and Visitor self-registration — all separately identified gaps, none in scope here.

## Decisions

### Design tokens alias Tailwind's existing scale, not new hex values

```css
@theme {
  --color-primary: var(--color-indigo-500);        /* mockup's #6366F1 */
  --color-primary-hover: var(--color-indigo-600);   /* mockup's #4F46E5 */
  --color-success: var(--color-emerald-500);
  --color-warning: var(--color-amber-500);
  --color-danger: var(--color-red-500);
  --color-surface: var(--color-white);
  --color-background: var(--color-slate-50);
  --color-border: var(--color-slate-200);
  --color-text: var(--color-slate-900);
  --color-text-muted: var(--color-slate-500);

  --text-h1: 2rem;      /* 32px/700, per the mockup's type scale */
  --text-h2: 1.5rem;    /* 24px/600 */
  --text-h3: 1.125rem;  /* 18px/600 */
}
```

The mockup's palette hex values are, shade-for-shade, Tailwind's own default indigo/slate/
emerald/amber/red at their standard steps — not a coincidence worth ignoring. Rejected:
hand-copying each hex value as a brand-new custom property (e.g. `--color-primary: #6366F1`
directly). That would work visually but throws away every adjacent shade (`indigo-100` for a
tinted background, `indigo-700` for a pressed state, etc.) that the alias approach keeps for
free — a future "primary/10" tint or hover-darker state is already available, not something to
invent later. Spacing and border-radius in the mockup already match Tailwind's default scale
closely enough that no `--spacing-*`/`--radius-*` overrides are needed.

### New dependencies: `lucide-react` and `@headlessui/react`

`lucide-react` — the mockup's icon set (home, users, upload, file, settings, edit, delete,
search, bell, logout) maps directly onto it; nothing in the app renders an icon today.

`@headlessui/react` — backs `ui/Modal`, the mobile sidebar drawer, and `ui/Select`. Rejected:
hand-rolling a modal with a plain `<div>` + manual `onKeyDown` for Escape and manual `tabIndex`
juggling for focus trapping. That's exactly the kind of accessibility surface (focus trap,
`aria-modal`, restoring focus on close, ESC-to-close) that's easy to get subtly wrong and directly
graded ("senior best practices," "cross-browser support considerations" in the brief) — a
maintained, unstyled, Tailwind-friendly library removes that risk for a small dependency cost.

### `components/ui/*` primitives, consumed by two thin domain layers

```
components/ui/       Button, Input, Select, Badge, Card, Modal, Avatar, Progress, Table
components/layout/   AppShell, Sidebar, Topbar     (replaces layouts/AdminLayout.tsx)
components/users/    UserStats, UserTable, UserRow, UserCard, UserForm, UserModal,
                     DeleteUserDialog, RoleBadge (maps role → ui/Badge variant)
components/imports/  ImportUploader, ImportHistoryTable, ImportRow, ImportCard,
                     ImportProgressModal, ImportStatusBadge (maps status → ui/Badge variant)
```

The mockup's own proposed shape used generic `pages/Users/Index.tsx`/`pages/Imports/Index.tsx`
naming — not adopted literally, since Inertia pages here are resolved by
`app/javascript/pages/<controller_path>/<action>.tsx` (matching Rails' `controller_path`/
`action_name`), so the real files are `pages/admin/users/index.tsx` and
`pages/admin/spreadsheet_imports/index.tsx`.

`ui/Avatar` (display, with an initials fallback like "JD" when `avatar_url` is null — today's
plain `<img>` has none) is kept separate from the existing `AvatarField` (the upload/URL-toggle
form input) — one is presentational, the other is a form control; conflating them would make
`AvatarField` harder to reuse in a context that just needs to *show* an avatar (e.g. the
sidebar's current-user avatar).

`ui/Badge` becomes the one place badge color/shape logic lives. `RoleBadge` (already exists,
today owns its own `STYLES` map) and the new `ImportStatusBadge` both become thin call sites
mapping a domain value to a `ui/Badge` variant, instead of each maintaining its own palette.

### User CRUD: modals fed by data the list already has, no new fetches

`Admin::UsersController` drops `new`/`edit`. The edit modal is seeded directly from the row
object already present in `index`'s `users` prop (`profile_json` output) — no request is made to
open it. Rejected: keeping an `edit` JSON-ish endpoint the modal calls on open. That would add a
network round-trip and a loading state for data the page already has in memory; the list is
already the source of truth for what a row looks like.

`create`/`update` **always** `redirect_to admin_users_path` now (success or failure) — there is
no more separate `new`/`edit` page to redirect back to on a validation error. The modal's
open/closed state is local React state, not URL-driven, so it naturally stays open on a failure
response:

```ts
form.post('/admin/users', { onSuccess: () => setModalOpen(false) })
```

`onSuccess` fires only after a clean redirect; a failed submission redirects to the *same* route
with `errors` populated, `onSuccess` never runs, and the mounted modal simply renders those
errors in place. This isn't a workaround for losing the old new/edit pages — it's simpler than
what page-based redirect-with-errors was already doing.

Deletion gains a real confirmation dialog (`DeleteUserDialog`, built on `ui/Modal`) in place of
`window.confirm(...)`. Rejected: leaving `confirm()` as-is. It already works, but a native
dialog can't be styled, isn't consistently testable via Playwright element queries (the next
branch's whole purpose), and sits awkwardly next to an otherwise fully modal-driven page.

### Imports: no `show` route at all — the modal always has data on open

Two ways `ImportProgressModal` can be opened, neither needing a dedicated fetch:

1. **From an existing history row** — that row's data is already the `summary_json` shape from
   the `index` action's `imports` prop; the modal seeds from it directly.
2. **Right after creating an import** — the history list is sorted newest-first (same convention
   as `Admin::UsersQuery`), so `imports.data[0]` after the create's redirect-triggered reload
   *is* the new import:
   ```ts
   form.post('/admin/spreadsheet_imports', { onSuccess: () => openModalFor(imports.data[0]) })
   ```
   Rejected: a one-off `created_import_id` prop set only on the create response. It would work,
   but duplicates information the list ordering already guarantees, for no real gain — one
   fewer prop to keep in sync beats a slightly more explicit signal here.

Either way, `useImportProgress` (unchanged) subscribes over the existing
`SpreadsheetImportChannel` once the modal is open, same live-update mechanism as today's `show`
page. `Admin::SpreadsheetImportsController#show` and its route/page are deleted entirely — kept
alive only through the `index` + modal path.

### `Admin::SpreadsheetImportsQuery` mirrors `Admin::UsersQuery`, with `.with_attached_file`

Same cursor-based `before_id`/`PER_PAGE = 25`/`fetched.size > PER_PAGE` shape as
`Admin::UsersQuery` — no reason to invent a second pagination strategy for a second admin list.
The one addition: `.with_attached_file` on the base scope. The history table needs each import's
filename (`import.file.filename`), and without eager-loading the attachment that's the exact
avatar N+1 already flagged in the diagnostic that started this branch, reproduced for imports
instead of Users if not guarded against here.

```ruby
def imports_json(imports)
  imports.map { |i| i.summary_json.merge(filename: i.file.filename.to_s, created_at: i.created_at) }
end
```
Same layering `Admin::UsersController#users_json` already does over `profile_json` —
`summary_json` itself stays untouched (still the one shape shared with every
`SpreadsheetImportChannel` broadcast); `filename`/`created_at` are list-only additions on top.

### `spreadsheet_import_id` on `users`: nullable, no backfill

```ruby
add_reference :users, :spreadsheet_import, foreign_key: true   # no null: false
```
```ruby
# User
belongs_to :spreadsheet_import, optional: true
# SpreadsheetImport
has_many :users
```
Existing Users (invited, or future self-registered) were never going to have an originating
import — `NULL` is the correct value for them, not a gap to backfill. `Imports::UserBatchInserter`
changes from `new(rows)` to `new(rows, import:)`, and its `attributes_for` adds
`spreadsheet_import_id: import.id` to the `insert_all` payload — the one place a row's insert
attributes are assembled.

## Risks / Trade-offs

- **[Removing `admin/users/{new,edit}` and `admin/spreadsheet_imports/{new,show}` is an internal
  breaking route change]** → Acceptable: nothing external links to these routes (no email links
  to an edit page, no bookmarked admin URLs called out anywhere in the specs), and the
  replacement (modal on the same list) is a strict UX upgrade, not a removed capability.
- **[Two render paths per list row — `UserRow`/`UserCard`, `ImportRow`/`ImportCard` — for the
  table-vs-card responsive split]** → Deliberate: a CSS-only `hidden md:table` / `md:hidden`
  toggle avoids any JS breakpoint detection (no hydration mismatch risk between server and
  client render), at the cost of two small presentational components per row type instead of
  one. Both read the same prop shape, so they can't drift on *data*, only on markup.
- **[`@headlessui/react` and `lucide-react` are new runtime dependencies]** → Both are small,
  widely-used, actively maintained, and directly address a graded concern (accessible modals,
  consistent iconography) rather than being nice-to-have additions; not adopted lightly, but a
  reasonable trade for what hand-rolling would cost in correctness risk.
- **[The User↔import association isn't surfaced in the UI]** → Confirmed non-goal for this
  change (see above) — the data is captured now specifically so a future change can display it
  without another migration; deferring the UI, not the traceability, was the deliberate split.

## Migration Plan

One additive migration (`add_reference :users, :spreadsheet_import, foreign_key: true`, nullable)
— no backfill, no data loss, rollback is a plain `remove_reference`. Every other change is
route/controller/frontend restructuring with no schema impact. Rollout order follows the
proposal's commit sequence (tokens → ui primitives → layout → backend association → imports
listing → Users page rebuild → Imports page rebuild), each commit leaving `bin/rails test` green
and (from the ui-primitives commit on) `npm run check` clean.

## Open Questions

- Whether to surface the new User↔import association in the UI (e.g. a small "via import #N" tag
  on a User row) is left for a follow-up change, not decided here either way.
