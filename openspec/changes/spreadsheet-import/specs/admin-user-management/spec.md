## MODIFIED Requirements

### Requirement: Toggle a User's role
An admin SHALL be able to change any User's role between `default` and `admin`, either through
the dedicated role action, or by setting a new User's initial role via the spreadsheet-import
capability. Role SHALL NOT be changeable through the single-user invite or edit actions.

#### Scenario: Changing a role
- **WHEN** an admin sets a User's role to `admin` or `default`
- **THEN** the User's role is updated and the admin is returned to the User list

#### Scenario: Invalid role value
- **WHEN** a role value other than `default` or `admin` is submitted
- **THEN** the role is not changed and a "invalid role" message is shown,
  without raising an unhandled error

#### Scenario: Role is not settable through create or edit
- **WHEN** a `role` value is submitted alongside the invite or edit form
- **THEN** it has no effect — the invite and edit actions do not accept a
  `role` parameter at all, so a single User's role can only change through the
  dedicated role action, or, at creation time only, through a spreadsheet import row (see the
  spreadsheet-import capability for that behavior)
