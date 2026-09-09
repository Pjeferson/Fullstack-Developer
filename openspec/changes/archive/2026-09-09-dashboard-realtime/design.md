## Context

See proposal.md for motivation. Builds directly on `feature/import-progress`'s Action Cable
plumbing (`ApplicationCable::Connection`/`Channel`, the `useChannel` hook, the Solid trifecta
now running in both development and production) — this branch adds a second channel and reuses
all of that infrastructure rather than duplicating it.

`Admin::UsersController#index` today renders every User in one response
(`User.order(id: :desc).map { ... }`, no limit) — fine at current scale, not at the scale a
paginated dashboard is meant to handle.

This app's installed versions already carry Inertia v2's infinite-scroll support:
`inertia_rails` 3.22.0 (`InertiaRails.scroll`, `lib/inertia_rails/scroll_prop.rb`/
`scroll_metadata.rb`) and `@inertiajs/react` 3.7.0 (`InfiniteScroll` component). Confirmed by
reading both packages' source directly rather than assuming — no version bump needed for either.

## Goals / Non-Goals

**Goals:**
- Live stats (total + per-role counts) on `/admin/users`, broadcast only from the exact
  mutation points that change a count.
- Paginated User list (25/page) that stays correct even if Users are created while an admin is
  scrolling.
- Small, single-purpose frontend components instead of one page component doing everything.

**Non-Goals:**
- Any change to what `/admin/users` requires authorization-wise — still `Admin::BaseController`.
- Any new page or route — the dashboard is a section on the existing `/admin/users` page.
- Historical/trend stats (counts over time, charts) — only current totals, per the user stories.
- Filtering or searching the User list — `Admin::UsersQuery` exists to isolate pagination, not
  to grow into a general-purpose filter builder; that's a future concern if ever needed.

## Decisions

### `Admin::UsersQuery`: cursor-based, not offset-based, pagination

```ruby
module Admin
  class UsersQuery
    PER_PAGE = 25

    def initialize(before_id: nil)
      @before_id = before_id
    end

    def records
      fetched.first(PER_PAGE)
    end

    def metadata
      {
        page_name: "before_id",
        current_page: before_id,
        previous_page: nil, # this list only ever loads forward — see below
        next_page: has_more? ? records.last&.id : nil
      }
    end

    private
      attr_reader :before_id

      def fetched
        @fetched ||= begin
          scope = User.order(id: :desc).limit(PER_PAGE + 1)
          scope = scope.where(User.arel_table[:id].lt(before_id)) if before_id
          scope.to_a
        end
      end

      def has_more? = fetched.size > PER_PAGE
  end
end
```

Rejected: plain `offset`/`limit` pagination (`page` param, page number). The list is sorted
newest-first, and an admin actively inviting/importing Users while another admin scrolls is a
completely normal scenario for this app (that's the point of `feature/spreadsheet-import`) —
with offset pagination, every new User inserted at the top shifts everyone below it by one,
which either re-shows a User already seen or skips one entirely on the next page load. A
`WHERE id < :before_id` cursor keyed off the last-seen row doesn't have this problem: it's
anchored to a specific row, not a shifting position, so it stays correct regardless of what gets
inserted above it. Fetching `PER_PAGE + 1` rows and slicing is a well-known trick to know
whether there's a next page without a separate `COUNT(*)` query.

`InertiaRails.scroll`'s `HashAdapter` metadata contract (`page_name`/`current_page`/
`previous_page`/`next_page`) doesn't require the values to be page *numbers* — `page_name` is
just the query param name the frontend re-sends on the next request, and here that's
`before_id` (a User id), not a page count. `previous_page` is always `nil` because this list
only ever loads more Users going forward (matches `InfiniteScroll`'s `onlyNext` mode) — there's
no "scroll up for older content" concept for a newest-first admin list.

### `Admin::UsersController#index`

```ruby
def index
  query = Admin::UsersQuery.new(before_id: params[:before_id])

  render inertia: "admin/users/index", props: {
    users: InertiaRails.scroll(query.metadata) { query.records.map { |u| u.profile_json.merge(created_at: u.created_at, updated_at: u.updated_at) } },
    stats: Dashboard::StatsQuery.new.call
  }
end
```

`stats` is a plain prop (not `scroll`/`merge`) — it's always the *current* totals, never
paginated or appended; `DashboardChannel` is what keeps it current after the initial load, not
another page of results.

### `Dashboard::StatsQuery` and `Dashboard::StatsBroadcaster`

```ruby
module Dashboard
  class StatsQuery
    def call
      { total: User.count, by_role: User.roles.keys.index_with { |role| User.where(role: role).count } }
    end
  end
end
```

`by_role` is built from `User.roles.keys` (not `User.group(:role).count` directly) specifically
so a role with zero Users still appears as `0` rather than being omitted — `group(...).count`
only returns keys that actually occur, which would silently drop e.g. `"admin" => 0` from the
payload the moment the last admin is demoted.

```ruby
module Dashboard
  class StatsBroadcaster
    def call
      ActionCable.server.broadcast("dashboard_stats", Dashboard::StatsQuery.new.call)
    end
  end
end
```

Called as `Dashboard::StatsBroadcaster.new.call` (not the bare `.call` shorthand) — matching
this project's established service convention (no `self.call` class-method shortcut, the same
choice already made for `Users::Inviter`/`Imports::ProgressBroadcaster`).

`DashboardChannel` broadcasts to a single fixed stream name (`"dashboard_stats"`, via
`ActionCable.server.broadcast`), not `stream_for`/`broadcast_to` — those are for streaming
updates about *one* record (like `SpreadsheetImportChannel` streaming one import); dashboard
stats aren't scoped to any record, every admin watches the same one global stream:

```ruby
class DashboardChannel < ApplicationCable::Channel
  def subscribed
    reject and return unless current_user&.admin?
    stream_from "dashboard_stats"
  end
end
```

### Broadcast call sites — explicit, not automatic

`Dashboard::StatsBroadcaster.new.call` is added at exactly the places a User is created,
destroyed, or has its role changed — never on a plain edit, which never changes a count:

- `Admin::UsersController#create` (invite), after a successful save
- `Admin::UsersController#destroy`, after `@user.destroy`
- `Admin::Users::RolesController#update`, after a successful role change
- `ProfilesController#destroy` (self-service account deletion) — deliberately included even
  though the user stories only named "criar, deletar, toggle de role" without specifying
  *which* delete path: a User deleting their own account changes the total exactly like an
  admin deleting them, and the existing `admin-user-management` spec already treats
  self-deletion as unexceptional (no special-casing) — the dashboard should stay accurate
  regardless of which delete path was used. Flagging this explicitly since it's an addition
  beyond what was asked, not a silent assumption.
- `SpreadsheetImportJob`, once per batch (alongside the existing `update_and_broadcast!` call,
  not a second broadcast mechanism) — not per row, for the same throughput reason
  `Imports::ProgressBroadcaster` itself is already only called once per batch
- **Not** `Admin::UsersController#update` — editing name/email/avatar never changes a count

### Frontend: two named hooks over the shared `useChannel` primitive

```ts
// useImportProgress.ts
export function useImportProgress(importId: number, onUpdate: (data: SpreadsheetImportSummary) => void) {
  useChannel<SpreadsheetImportSummary>('SpreadsheetImportChannel', { id: importId }, onUpdate)
}

// useDashboardStats.ts
export function useDashboardStats(onUpdate: (data: DashboardStats) => void) {
  useChannel<DashboardStats>('DashboardChannel', {}, onUpdate)
}
```

`useChannel` (added in `feature/import-progress`) stays the one place subscribe/unsubscribe
lifecycle is implemented; these two hooks just name a channel + payload type so call sites read
as "what data am I watching," not "which channel string and shape am I wiring up this time."
`show.tsx` is updated to call `useImportProgress` instead of `useChannel` directly, so both
live-data pages in the app follow the same shape.

### Frontend componentization

`admin/users/index.tsx` today is a single component rendering the whole table inline. With a
stats section and pagination added to the same page, that would grow into one large component
mixing three concerns. Split into:

- `admin/users/index.tsx` — the page: holds `stats` state (seeded from props, updated via
  `useDashboardStats`), renders `<DashboardStats stats={stats} />` and `<UsersTable ... />`
  wrapped in `<InfiniteScroll data="users">`.
- `components/admin/DashboardStats.tsx` — total + per-role counts, presentational only.
- `components/admin/UsersTable.tsx` — the `<table>` shell (headers, `<InfiniteScroll>`'s items
  container), maps over Users rendering `<UserRow>`.
- `components/admin/UserRow.tsx` — one row: fields + the existing promote/demote, edit, delete
  actions (moved out of `index.tsx`, behavior unchanged). Reuses the existing `RoleBadge`.

## Risks / Trade-offs

- **[Cursor pagination can't jump to an arbitrary page]** → not needed here: `InfiniteScroll`
  only ever asks for "the next batch," never "page 7." Acceptable; a jump-to-page UI isn't part
  of this proposal.
- **[`fetched.size > PER_PAGE` still runs a `PER_PAGE + 1`-row query per scroll step]** →
  cheaper than a separate `COUNT(*)` (which would scan/estimate over the whole remaining table
  as it grows) and cheaper than fetching a full extra page; this is the standard trade-off for
  offset-free "is there more" pagination.
- **[Two broadcast mechanisms now exist side by side — `Imports::ProgressBroadcaster` and
  `Dashboard::StatsBroadcaster`]** → deliberately not unified into one generic broadcaster: one
  streams one record's state to a per-record channel, the other streams global aggregate state
  to a single fixed channel — different enough shapes that a shared abstraction would be
  forcing two different things to look the same rather than removing real duplication.

## Migration Plan

One migration (`add_index :users, :role`), safely additive — no data change, no downtime
concern at this app's scale.
