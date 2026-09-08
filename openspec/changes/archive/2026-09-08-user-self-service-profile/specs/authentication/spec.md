## MODIFIED Requirements

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
