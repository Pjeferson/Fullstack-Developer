# Admin User Management Specification

## Purpose
Lets an admin User list, invite, edit, and delete other Users, and toggle
a User's role, from an admin-only area of the app (`/admin/users`). This
is the only place a User's role can change, and the only place a User
account other than one's own can be created or removed.

## Requirements

### Requirement: Admin-only access
Every action under `/admin` SHALL be reachable only by an authenticated
User whose role is `admin`.

#### Scenario: Guest
- **WHEN** an unauthenticated visitor requests any `/admin` page
- **THEN** they are redirected to sign in first (the app-wide
  authentication requirement applies before the admin check)

#### Scenario: Authenticated non-admin
- **WHEN** an authenticated User whose role is not `admin` requests any
  `/admin` page
- **THEN** they are redirected to the root page with a "not authorized"
  message

### Requirement: List Users
An admin SHALL be able to see every User in the system.

#### Scenario: Viewing the list
- **WHEN** an admin visits `/admin/users`
- **THEN** every User is shown with their email, full name, role, and
  avatar status (set / processing / failed / none)

### Requirement: Invite a User
An admin SHALL be able to create a new User by email address and full
name, without setting that User's password directly.

#### Scenario: Successful invite
- **WHEN** an admin submits a unique, validly-formatted email address and
  a full name
- **THEN** a new User is created with role `default`, a random password
  the admin never sees or sets (making the account unusable until the
  invitee acts), and a password-reset email is sent to the invitee so
  they can set their own password through the existing password-reset
  flow

#### Scenario: Invalid or duplicate email
- **WHEN** an admin submits a blank/invalid email address, a blank full
  name, or an email address already in use by another User
- **THEN** no User is created and the form is redisplayed with the
  validation errors

### Requirement: Edit a User
An admin SHALL be able to change a User's email address, full name, and
avatar.

#### Scenario: Successful update
- **WHEN** an admin submits a valid email address and full name for an
  existing User
- **THEN** the User's record is updated and the admin is returned to the
  User list

#### Scenario: Invalid update
- **WHEN** an admin submits a blank/invalid email address, a blank full
  name, or an email address already used by a different User
- **THEN** the User is not updated and the edit form is redisplayed with
  the validation errors

### Requirement: Delete a User
An admin SHALL be able to permanently remove a User, including their own
account.

#### Scenario: Deleting a User
- **WHEN** an admin deletes a User
- **THEN** that User, their sessions, and their avatar attachment are
  removed, and the admin is returned to the User list

#### Scenario: Deleting one's own account
- **WHEN** an admin deletes their own User account
- **THEN** the deletion proceeds like any other — there is no special
  restriction against self-deletion (regular Users are expected to be
  able to delete their own account through self-service later, so an
  admin doing it to themselves is not treated as an edge case)

### Requirement: Set a User's avatar from an uploaded file
An admin SHALL be able to attach an avatar image to a User by uploading a
file directly.

#### Scenario: Valid upload
- **WHEN** an admin uploads a PNG, JPEG, WEBP, or GIF file of 5MB or less
  while creating or editing a User
- **THEN** the file is attached to the User as their avatar immediately
  (synchronously, in the same request), replacing any previous avatar

#### Scenario: Rejected upload
- **WHEN** an admin uploads a file of a different type, or larger than
  5MB
- **THEN** the avatar is not attached and the form is redisplayed with a
  validation error naming the reason

### Requirement: Set a User's avatar from a remote URL
An admin SHALL be able to attach an avatar image to a User by pasting a
URL, as an alternative to uploading a file.

#### Scenario: Valid remote image
- **WHEN** an admin submits a URL while creating or editing a User (and
  does not also upload a file)
- **THEN** the User is marked as having their avatar in progress, and a
  background job downloads the URL, validates its content type and size
  exactly as an upload would be, and attaches it as the User's avatar on
  success

#### Scenario: Blocked or invalid remote URL
- **WHEN** the submitted URL resolves to a private, loopback, or
  link-local address (directly or via a redirect), or the downloaded
  content fails the content-type or size check
- **THEN** no avatar is attached, the User's in-progress state is
  cleared, and an error describing the failure is recorded on the User
  for the admin to see

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
