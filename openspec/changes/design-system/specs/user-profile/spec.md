## MODIFIED Requirements

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
