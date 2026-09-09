# visitor-registration Specification

## Purpose
Lets a Visitor create their own `default`-role User account without an admin's involvement, and
governs how the root path behaves depending on whether the visitor is already signed in.

## Requirements

### Requirement: Register as a new User
A Visitor SHALL be able to create their own account by submitting a full name, email address,
and password. The created account SHALL always have the `default` role.

#### Scenario: Successful registration
- **WHEN** a Visitor submits a non-blank full name, a unique validly-formatted email address,
  and a non-blank password
- **THEN** a new User is created with role `default`, they are immediately signed in (a Session
  is created and the session cookie is set), and they are redirected to their profile

#### Scenario: Invalid or duplicate email
- **WHEN** a Visitor submits a blank/invalid email address, or an email address already in use
  by another User
- **THEN** no User is created, no session is started, and the registration form is redisplayed
  with the validation errors

#### Scenario: Blank full name or password
- **WHEN** a Visitor submits a blank full name or a blank password
- **THEN** no User is created and the registration form is redisplayed with the validation
  errors

#### Scenario: Role is not settable through registration
- **WHEN** a `role` value is submitted alongside the registration form
- **THEN** it has no effect — the registration action does not accept a `role` parameter at all,
  so a self-registered User can never become an admin this way

#### Scenario: Registration updates live dashboard stats
- **WHEN** a Visitor successfully registers
- **THEN** the admin dashboard's live User counts (total and by role) update the same way they
  do for an admin invite, an admin deleting a User, or a spreadsheet-import batch

### Requirement: Root path reflects session state
The root path SHALL send an unauthenticated visitor to sign in, and send an already-authenticated
visitor straight to their own landing page instead of showing the sign-in or registration form
again.

#### Scenario: Unauthenticated visitor at the root
- **WHEN** a visitor with no active session requests the root path
- **THEN** they see the sign-in page

#### Scenario: Authenticated visitor revisits sign-in or registration
- **WHEN** an already-authenticated User requests the root path, the sign-in page, or the
  registration page
- **THEN** they are redirected to their landing page (the admin User list for an admin, their own
  profile for anyone else) instead of seeing the form
