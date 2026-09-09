## MODIFIED Requirements

### Requirement: List Users
An admin SHALL be able to see every User in the system, loaded 25 at a time (newest first) as
they scroll, rather than all at once.

#### Scenario: Viewing the list
- **WHEN** an admin visits `/admin/users`
- **THEN** the first 25 Users (newest first) are shown, each with their email, full name, role,
  and avatar status (set / processing / failed / none)

#### Scenario: Loading more Users
- **WHEN** an admin scrolls near the bottom of the User list and more Users exist beyond what's
  currently shown
- **THEN** the next 25 Users are loaded and appended to the list automatically, without a full
  page reload

#### Scenario: Reaching the end of the list
- **WHEN** every User has been loaded
- **THEN** scrolling further loads nothing more, and no further request is made
