# user-profile Specification

## Purpose
Lets any signed-in User view, edit, and delete their own account —
without needing an admin, and without any access to other Users'
accounts. This is separate from admin-user-management, which lets an
admin manage any User but is unreachable by a non-admin.

## Requirements

### Requirement: View own profile
A signed-in User SHALL be able to see their own email address, full name,
role, and avatar.

#### Scenario: Viewing the profile page
- **WHEN** a signed-in User visits their profile page
- **THEN** their email address, full name, role, and avatar are shown;
  role is shown read-only

### Requirement: Edit own profile
A signed-in User SHALL be able to change their own email address, full
name, and avatar. A User SHALL NOT be able to change their own role, or
view or edit any other User's account, through this capability.

#### Scenario: Successful update
- **WHEN** a signed-in User submits a valid, unique email address and a
  non-blank full name for their own account
- **THEN** their record is updated

#### Scenario: Invalid update
- **WHEN** a signed-in User submits a blank/invalid email address, a
  blank full name, or an email address already used by a different User
- **THEN** their record is not updated and the form is redisplayed with
  the validation errors

#### Scenario: Role is not editable
- **WHEN** a `role` value is submitted with the profile update
- **THEN** it has no effect — the update does not accept a `role`
  parameter at all

#### Scenario: Avatar from an uploaded file
- **WHEN** a signed-in User uploads a PNG, JPEG, WEBP, or GIF file of 5MB
  or less as their avatar
- **THEN** the file is attached as their avatar immediately, replacing
  any previous avatar

#### Scenario: Avatar from a remote URL
- **WHEN** a signed-in User submits a URL as their avatar instead of
  uploading a file
- **THEN** their avatar is marked as in-progress and a background job
  downloads and validates it exactly as the admin capability's avatar
  handling does (content-type/size checks, blocked on private/internal
  addresses), attaching it as their avatar on success or recording an
  error on failure

#### Scenario: No access to another User's profile
- **WHEN** a signed-in User requests the profile edit or view for any
  User other than themselves
- **THEN** there is no route or parameter that identifies a different
  User to view or edit — the profile capability always operates on the
  signed-in User's own record

### Requirement: Delete own profile
A signed-in User SHALL be able to permanently delete their own account, after confirming the
action in a dialog.

#### Scenario: Confirming deletion
- **WHEN** a User chooses to delete their own account from the profile page
- **THEN** a confirmation dialog appears before anything is removed

#### Scenario: Deleting one's own account
- **WHEN** a signed-in User confirms the deletion of their own account
- **THEN** their User record, sessions, and avatar attachment are
  removed, their current session is destroyed, the session cookie is
  cleared, and they are redirected to sign in with a confirmation message

#### Scenario: Cancelling deletion
- **WHEN** a User dismisses or cancels the confirmation dialog
- **THEN** their account is not removed
