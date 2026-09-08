# Authentication Specification

## Purpose
Lets a User sign in and out with email/password, and recover access via a
self-service password reset. Session-based (signed cookie, DB-backed
session record), not token/JWT-based. Every controller in the app requires
an authenticated session by default; a controller must opt out explicitly
to allow unauthenticated access.

## Requirements

### Requirement: Sign in with email and password
A User SHALL be able to start a session by submitting their email address
and password.

#### Scenario: Valid credentials
- **WHEN** a User submits their email address and correct password
- **THEN** a new Session record is created, a signed, httponly, permanent
  session cookie is set, and the request is redirected to the page the
  User originally tried to reach; if there was none, a non-admin User is
  redirected to their own profile and an admin User is redirected to the
  admin User list

#### Scenario: Invalid credentials
- **WHEN** a User submits an unknown email address or an incorrect
  password
- **THEN** no Session is created, no session cookie is set, and the
  request is redirected back to the sign-in page with a generic
  "Try another email address or password" message (the response does not
  reveal whether the email address exists)

#### Scenario: Sign-in rate limiting
- **WHEN** more than 10 sign-in attempts occur from the same source within
  a 3 minute window
- **THEN** further attempts in that window are rejected with a
  "Try again later" message instead of being checked against credentials

### Requirement: Sign out
An authenticated User SHALL be able to end their session.

#### Scenario: Sign out
- **WHEN** an authenticated User signs out
- **THEN** their Session record is destroyed and the session cookie is
  cleared

### Requirement: Authentication required by default
Every controller action SHALL require an authenticated session unless it
explicitly opts out.

#### Scenario: Unauthenticated request to a protected page
- **WHEN** a request without a valid session cookie is made to a
  controller action that has not called `allow_unauthenticated_access`
- **THEN** the request is redirected to the sign-in page, and the
  originally requested URL is remembered so the User returns there after
  signing in

#### Scenario: Explicit opt-out
- **WHEN** a controller action calls `allow_unauthenticated_access`
  (e.g. the sign-in and password-reset actions)
- **THEN** that action is reachable without an authenticated session

### Requirement: Self-service password reset
A visitor who knows a User's email address SHALL be able to request a
password-reset link, and a User with a valid, unused, unexpired link
SHALL be able to set a new password.

#### Scenario: Requesting a reset link
- **WHEN** a visitor submits an email address on the "forgot password"
  form
- **THEN** if a User with that email exists, a password-reset email is
  enqueued for that User; the response message is identical whether or
  not the email address is registered, to avoid leaking which addresses
  have accounts

#### Scenario: Reset link expiry and reuse
- **WHEN** a password-reset link is opened more than 15 minutes after it
  was generated, or after the User's password has already been changed
  since it was generated
- **THEN** the link is rejected as invalid or expired, and the visitor is
  redirected to request a new one

#### Scenario: Setting a new password
- **WHEN** a User submits a matching new password and confirmation
  through a valid, unexpired reset link
- **THEN** the password is updated, every existing Session for that User
  is destroyed (so any other signed-in device is signed out), and the
  User is redirected to sign in with their new password
