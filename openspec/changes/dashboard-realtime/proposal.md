## Why

An admin currently has no at-a-glance view of the User base — only the list itself, unpaginated
(every User rendered at once). This adds a live-updating stats section (total Users, Users by
role) directly above the existing User list, and paginates that list so it stays fast as the
User base grows. Per the roadmap this is `feature/dashboard-realtime` — "counters via Solid
Cable" — parallel to and independent of `feature/spreadsheet-import`/`feature/import-progress`,
now both merged.

## What Changes

- **No new page, no new route.** `/admin/users` becomes the dashboard: a stats section is added
  above the existing User list on the same page. An admin is already redirected here after
  login (`after_authentication_url`, unchanged) — the "redirected to the Dashboard after login"
  requirement is satisfied by existing behavior, not new code.
- **Live stats**: total User count and a count per role, computed by `Dashboard::StatsQuery` and
  pushed over a new `DashboardChannel` (admin-only, like every other channel in this app) via
  `Dashboard::StatsBroadcaster`. Broadcast explicitly, from the exact places User counts
  actually change: inviting a User, deleting a User (admin-initiated or self-service), toggling
  a role, and once per batch during a spreadsheet import — never on a plain edit (name/email/
  avatar), which doesn't change any count. Same reasoning as `feature/import-progress`'s
  `Imports::ProgressBroadcaster`: an explicit call at each real mutation site, not an
  ActiveRecord callback, so the side effect of broadcasting stays visible at its call site
  instead of implicit in the model.
- **The User list paginates**, 25 at a time, using Inertia's native infinite-scroll support
  (`InertiaRails.scroll` + the `<InfiniteScroll>` component — already available in the versions
  installed, no new dependency) instead of rendering every User in one response. Pagination is
  cursor-based (`WHERE id < :last_seen_id`), not offset-based — see design.md for why, given the
  list is already sorted newest-first.
- **The list query moves into its own object**, `Admin::UsersQuery`, out of the controller —
  the controller's job becomes "call the query, render the page," not "know how pagination
  works."
- **Adds an index on `users.role`**, since it's now grouped on every stats computation (and
  every live update), not just read per-row.
- **Frontend**: two new hooks, `useImportProgress` and `useDashboardStats`, both built on the
  existing generic `useChannel` (which `feature/import-progress` already added and keeps being
  the shared low-level primitive) — `show.tsx`'s existing inline `useChannel(...)` call is
  refactored to use `useImportProgress`, so both live-data pages follow the same pattern.
  `admin/users/index.tsx` is split into small components (`DashboardStats`, `UsersTable`,
  `UserRow`) instead of growing into one large page component, since the stats section, the
  list, and pagination all now live on the same page.

## Capabilities

### New Capabilities
- `admin-dashboard`: an admin-only live stats section (total Users, Users by role) shown above
  the User list on `/admin/users`, updating in real time as Users are created, deleted, or have
  their role changed.

### Modified Capabilities
- `admin-user-management`: the "List Users" requirement changes from showing every User at once
  to paginating 25 at a time via infinite scroll.

## Impact

- New migration: `add_index :users, :role`.
- New: `app/queries/admin/users_query.rb`, `app/queries/dashboard/stats_query.rb`,
  `app/services/dashboard/stats_broadcaster.rb`, `app/channels/dashboard_channel.rb`,
  `app/javascript/hooks/useImportProgress.ts`, `app/javascript/hooks/useDashboardStats.ts`,
  new `app/javascript/components/admin/{DashboardStats,UsersTable,UserRow}.tsx`.
- Changed: `Admin::UsersController#index` (query object + stats + scroll prop),
  `Admin::UsersController#create`/`#destroy`, `Admin::Users::RolesController#update`,
  `ProfilesController#destroy`, `SpreadsheetImportJob` (each gains a stats-broadcast call at
  the point they actually change a count), `admin/users/index.tsx` (componentized),
  `show.tsx` (refactored onto `useImportProgress`).
- No changes to `Admin::UsersController#update`, `Imports::*`, or any existing spec's other
  requirements.
