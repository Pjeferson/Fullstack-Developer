## 1. Role index and stats query

- [x] 1.1 Add migration `add_index :users, :role` and run `bin/rails db:migrate`
- [x] 1.2 Add `app/queries/dashboard/stats_query.rb` (`#call` returns `{ total:, by_role: }`,
  `by_role` built from `User.roles.keys` so a zero-count role still appears) and
  `test/queries/dashboard/stats_query_test.rb` covering: correct total and per-role counts; a
  role with zero Users is present in `by_role` as `0`, not omitted

## 2. Dashboard channel and broadcaster

- [ ] 2.1 Add `app/channels/dashboard_channel.rb` (`subscribed` rejects unless
  `current_user&.admin?`, otherwise `stream_from "dashboard_stats"`) and
  `test/channels/dashboard_channel_test.rb` covering: an admin subscribing is confirmed and
  streaming; a non-admin is rejected
- [ ] 2.2 Add `app/services/dashboard/stats_broadcaster.rb` (`new.call` —
  `ActionCable.server.broadcast("dashboard_stats", Dashboard::StatsQuery.new.call)`) and
  `test/services/dashboard/stats_broadcaster_test.rb` covering it broadcasts the current stats
  on the `dashboard_stats` stream (`assert_broadcast_on`)
- [ ] 2.3 Call `Dashboard::StatsBroadcaster.new.call` from `Admin::UsersController#create` (on
  success), `Admin::UsersController#destroy`, `Admin::Users::RolesController#update` (on
  success), and `ProfilesController#destroy`; extend each controller's existing test file with a
  case asserting the broadcast happens on success (`assert_broadcast_on`) and — for `create`
  and `RolesController#update` — that it does *not* broadcast on a failed/invalid request; also
  add a case to `Admin::UsersControllerTest` confirming `#update` (plain edit) does not broadcast
- [ ] 2.4 Call `Dashboard::StatsBroadcaster.new.call` from `SpreadsheetImportJob`'s existing
  `update_and_broadcast!` batch call site (once per batch, alongside the existing
  `Imports::ProgressBroadcaster` call — not a new per-row call), and extend
  `spreadsheet_import_job_test.rb` with a case asserting a `dashboard_stats` broadcast happens
  once per batch during a run

## 3. Paginated User list

- [ ] 3.1 Add `app/queries/admin/users_query.rb` (`new(before_id:).records`/`.metadata` — cursor
  pagination via `WHERE id < :before_id`, `PER_PAGE = 25`, fetch `PER_PAGE + 1` to detect more
  without a separate count; see design.md) and `test/queries/admin/users_query_test.rb`
  covering: first page returns the 25 newest Users; `metadata.next_page` is the 26th User's id
  when more exist, `nil` when exhausted; passing `before_id` returns the next 25 older than that
  id; a User created after an earlier page was fetched doesn't appear again or shift what a
  later page (fetched with an already-known `before_id`) returns
- [ ] 3.2 Update `Admin::UsersController#index` to use `Admin::UsersQuery` and
  `InertiaRails.scroll` for `users`, and add `stats: Dashboard::StatsQuery.new.call` to the
  props; update `test/controllers/admin/users_controller_test.rb`'s list test(s) for the new
  props shape (paginated `users` + `stats`), and add a case requesting a second page via
  `before_id` and asserting it returns the next batch, not the same one

## 4. Frontend hooks

- [ ] 4.1 Add `app/javascript/hooks/useImportProgress.ts` (wraps `useChannel` for
  `SpreadsheetImportChannel`) and update `admin/spreadsheet_imports/show.tsx` to use it instead
  of calling `useChannel` directly
- [ ] 4.2 Add `app/javascript/hooks/useDashboardStats.ts` (wraps `useChannel` for
  `DashboardChannel`) and the `DashboardStats` type to `app/javascript/types/index.ts`
- [ ] 4.3 Confirm `npm run check` is clean

## 5. Dashboard section and paginated list on the frontend

- [ ] 5.1 Add `app/javascript/components/admin/DashboardStats.tsx` (total + per-role counts,
  presentational)
- [ ] 5.2 Add `app/javascript/components/admin/UserRow.tsx` (one row's fields + existing
  promote/demote, edit, delete actions, extracted from `admin/users/index.tsx` with behavior
  unchanged) and `app/javascript/components/admin/UsersTable.tsx` (table shell mapping Users to
  `UserRow`)
- [ ] 5.3 Update `admin/users/index.tsx`: hold `stats` in state seeded from props and updated via
  `useDashboardStats`, render `<DashboardStats>` above an `<InfiniteScroll data="users" onlyNext>`
  wrapping `<UsersTable>`, confirm the existing promote/demote/edit/delete actions still work
  through the extracted `UserRow`
- [ ] 5.4 Confirm `npm run check` is clean

## 6. Full verification

- [ ] 6.1 Run `bin/rails test` (full suite green), `bin/rubocop`, and `bin/brakeman` with no new
  offenses
- [ ] 6.2 Manual smoke test via a running `bin/rails server` + `bin/jobs`: seed enough Users to
  span multiple pages (or reuse a large CSV like the earlier manual-test file), confirm the
  dashboard shows correct totals, scrolling loads more Users without a full reload, and inviting/
  deleting/toggling a role from one browser session updates the stats live in another
  subscribed session (or via a second `SpreadsheetImportChannel`-style script client, since this
  sandbox has no browser — see `feature/import-progress`'s verification notes for that approach)
