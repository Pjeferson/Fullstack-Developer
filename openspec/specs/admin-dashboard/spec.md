# admin-dashboard Specification

## Purpose
TBD - created by archiving change dashboard-realtime. Update Purpose after archive.
## Requirements
### Requirement: View User statistics on the admin dashboard
An admin SHALL be able to see the total number of Users and the number of Users per role on
`/admin/users`, above the User list.

#### Scenario: Viewing the dashboard
- **WHEN** an admin visits `/admin/users`
- **THEN** the total number of Users and a count of Users for each role (`default`, `admin`)
  are shown, reflecting the database at the time of the request

#### Scenario: A role with no Users
- **WHEN** no User currently has a given role
- **THEN** that role's count is shown as 0, not omitted

### Requirement: Dashboard statistics update live
While an admin has `/admin/users` open, the statistics SHALL update on their own as the User
count or role breakdown changes, without a manual reload.

#### Scenario: Inviting or deleting a User
- **WHEN** any admin invites a new User, deletes a User (including a User deleting their own
  account through self-service), or a spreadsheet import creates Users
- **THEN** every admin currently viewing the dashboard sees the total (and, for role-affecting
  changes, the per-role counts) update without reloading the page

#### Scenario: Toggling a User's role
- **WHEN** any admin changes a User's role
- **THEN** every admin currently viewing the dashboard sees the per-role counts update
  (the total is unaffected)

#### Scenario: Editing a User does not affect the dashboard
- **WHEN** a User's full name, email address, or avatar is changed
- **THEN** no dashboard update is triggered — the total and role counts are unaffected by that
  change

#### Scenario: Only an admin receives dashboard updates
- **WHEN** a non-admin or an unauthenticated visitor attempts to subscribe to dashboard updates
- **THEN** the subscription is rejected

### Requirement: The dashboard is where an admin already lands
An admin SHALL be directed to the same page the dashboard lives on after signing in.

#### Scenario: Redirected here after signing in
- **WHEN** an admin signs in with no prior page to return to
- **THEN** they are redirected to `/admin/users`, where the dashboard and the User list are
  both shown — this is existing sign-in behavior (see the `authentication` capability),
  unchanged by this capability

