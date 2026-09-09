# spreadsheet-import Specification

## Purpose
Lets an admin bulk-create Users from a CSV or XLSX file instead of inviting them one at a time,
processed in the background with progress that survives a page refresh and a worker restart.

## Requirements

### Requirement: Upload a spreadsheet to import Users
An admin SHALL be able to upload a CSV or XLSX file where each row describes one User to
create. The upload request SHALL return immediately; the file SHALL be processed
asynchronously.

#### Scenario: Successful upload
- **WHEN** an admin uploads a valid CSV or XLSX file
- **THEN** an import record is created in a pending/processing state and the admin is
  redirected to a page showing that import's status, without waiting for any row to be
  processed

#### Scenario: Unsupported file type
- **WHEN** an admin uploads a file that is neither CSV nor XLSX
- **THEN** the upload is rejected with a validation error and no import record is processed

#### Scenario: Non-admin access
- **WHEN** a non-admin or guest requests the import upload page or endpoint
- **THEN** they are blocked the same way every other admin-only page blocks them (redirected to
  sign in, or redirected with an authorization error, per the existing admin-area behavior)

### Requirement: Each row becomes a User, or a recorded failure
A row SHALL create exactly one new User when its email address and full name are valid and not
already in use; otherwise it SHALL be recorded as a failed row without affecting any existing
User, and the rest of the file SHALL continue processing.

#### Scenario: New unique row
- **WHEN** a row has a valid, not-yet-used email address and a non-blank full name
- **THEN** a new User is created with that email address and full name, the `default` role, and
  a password the User does not know (usable only through the "forgot password" flow)

#### Scenario: Duplicate email
- **WHEN** a row's email address already belongs to an existing User
- **THEN** that row is recorded as a failure, no existing User is modified, and processing
  continues with the remaining rows

#### Scenario: Invalid row
- **WHEN** a row has a blank/invalid email address or a blank full name
- **THEN** that row is recorded as a failure and processing continues with the remaining rows

#### Scenario: Optional role column
- **WHEN** a row includes a `role` column set to `default` or `admin`
- **THEN** the created User's initial role is set accordingly, instead of the usual `default`

#### Scenario: Missing role column
- **WHEN** a row has no `role` column, or the column is blank
- **THEN** the created User's role is `default`

#### Scenario: Invalid role value
- **WHEN** a row's `role` column is present and set to anything other than `default` or
  `admin`
- **THEN** that row is recorded as a failure and no User is created for it — an invalid role is
  never silently coerced to `default`

#### Scenario: No invite email sent
- **WHEN** the import creates a new User
- **THEN** no email is sent to that User as part of the import (unlike the single-user admin
  invite flow); the admin is expected to communicate access separately

### Requirement: Optional avatar by URL per row
A row MAY include an avatar URL. When present and the row's User is created successfully, the
avatar SHALL be fetched and attached the same way the existing admin avatar-by-URL flow does,
including its safety checks.

#### Scenario: Row with an avatar URL
- **WHEN** a row that successfully creates a User includes an avatar URL
- **THEN** that avatar is downloaded and validated (content-type and size checked, blocked on
  private/internal addresses) and attached on success, or an avatar error is recorded on that
  User on failure — without blocking or failing the row's User creation

#### Scenario: Duplicate row's avatar URL is never fetched
- **WHEN** a row is recorded as a duplicate-email failure and includes an avatar URL
- **THEN** that URL is never fetched, since no User was created for that row

### Requirement: Import progress is persisted and resumable
The state of an import (how many rows are expected, how many have been processed, how many
succeeded or failed) SHALL be persisted so it survives a page refresh, and SHALL allow the
import to resume from where it stopped if interrupted, without duplicating Users or re-emailing
anyone already processed.

#### Scenario: Viewing an in-progress or finished import
- **WHEN** an admin (re)visits the page for an import they started
- **THEN** the current counts (processed, succeeded, failed) and status are shown, reflecting
  persisted state rather than requiring the original upload request or an open connection

#### Scenario: Resuming after an interruption
- **WHEN** the import job is interrupted partway through (e.g. a worker restart) and later
  retried
- **THEN** processing continues from the last completed portion of the file — rows already
  successfully imported are not duplicated, and rows not yet reached are still processed

#### Scenario: Live updates are a separate capability
- **WHEN** an import is processing
- **THEN** this capability does not itself push live updates to the page — a persisted status
  that a page load (or manual refresh) can read is sufficient; real-time updates while the page
  is open are covered separately

#### Scenario: No per-row failure detail
- **WHEN** one or more rows fail (duplicate email, invalid data, or an invalid role)
- **THEN** only the aggregate failed-row count increases — no reason is persisted for any
  individual row; an admin who needs to know which rows failed and why has to fix the file and
  re-upload it
