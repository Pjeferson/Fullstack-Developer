## MODIFIED Requirements

### Requirement: Invite a User
An admin SHALL be able to create a new User by email address and full
name, without setting that User's password directly, from a modal opened
on the User list — without navigating to a separate page.

#### Scenario: Successful invite
- **WHEN** an admin submits a unique, validly-formatted email address and
  a full name from the create-User modal
- **THEN** a new User is created with role `default`, a random password
  the admin never sees or sets (making the account unusable until the
  invitee acts), a password-reset email is sent to the invitee so
  they can set their own password through the existing password-reset
  flow, and the modal closes, returning the admin to the updated User list

#### Scenario: Invalid or duplicate email
- **WHEN** an admin submits a blank/invalid email address, a blank full
  name, or an email address already in use by another User
- **THEN** no User is created and the modal stays open, showing the
  validation errors, without navigating away from the User list

### Requirement: Edit a User
An admin SHALL be able to change a User's email address, full name, and
avatar from a modal opened on the User list — without navigating to a
separate page. The modal is pre-filled from the User's data already
shown in the list, without a separate request to load it.

#### Scenario: Successful update
- **WHEN** an admin submits a valid email address and full name for an
  existing User from that User's edit modal
- **THEN** the User's record is updated and the modal closes, returning
  the admin to the updated User list

#### Scenario: Invalid update
- **WHEN** an admin submits a blank/invalid email address, a blank full
  name, or an email address already used by a different User
- **THEN** the User is not updated and the modal stays open, showing the
  validation errors, without navigating away from the User list

### Requirement: Delete a User
An admin SHALL be able to permanently remove a User, including their own
account, after confirming the action in a dialog.

#### Scenario: Confirming deletion
- **WHEN** an admin chooses to delete a User
- **THEN** a confirmation dialog naming that User appears before anything
  is removed

#### Scenario: Deleting a User
- **WHEN** an admin confirms the deletion of a User
- **THEN** that User, their sessions, and their avatar attachment are
  removed, and the admin sees the updated User list

#### Scenario: Cancelling deletion
- **WHEN** an admin dismisses or cancels the confirmation dialog
- **THEN** the User is not removed

#### Scenario: Deleting one's own account
- **WHEN** an admin confirms the deletion of their own User account
- **THEN** the deletion proceeds like any other — there is no special
  restriction against self-deletion (regular Users are expected to be
  able to delete their own account through self-service later, so an
  admin doing it to themselves is not treated as an edge case)
