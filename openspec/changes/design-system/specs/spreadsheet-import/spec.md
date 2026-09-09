## MODIFIED Requirements

### Requirement: Upload a spreadsheet to import Users
An admin SHALL be able to upload a CSV or XLSX file where each row describes one User to
create. The upload request SHALL return immediately; the file SHALL be processed
asynchronously.

#### Scenario: Successful upload
- **WHEN** an admin uploads a valid CSV or XLSX file from the imports page
- **THEN** an import record is created in a pending/processing state, the admin stays on the
  imports page, and a progress modal for that import opens automatically, without waiting for
  any row to be processed

#### Scenario: Unsupported file type
- **WHEN** an admin uploads a file that is neither CSV nor XLSX
- **THEN** the upload is rejected with a validation error and no import record is processed

#### Scenario: Non-admin access
- **WHEN** a non-admin or guest requests the import upload page or endpoint
- **THEN** they are blocked the same way every other admin-only page blocks them (redirected to
  sign in, or redirected with an authorization error, per the existing admin-area behavior)

### Requirement: Import progress is persisted and resumable
The state of an import (how many rows are expected, how many have been processed, how many
succeeded or failed) SHALL be persisted so it survives a page refresh, and SHALL allow the
import to resume from where it stopped if interrupted, without duplicating Users or re-emailing
anyone already processed. While an import is processing, an admin viewing its progress modal
SHALL see its counts and status update live, without needing to manually refresh.

#### Scenario: Viewing an in-progress or finished import
- **WHEN** an admin opens the progress modal for an import they started, either from the import
  history or immediately after uploading it
- **THEN** the current counts (processed, succeeded, failed) and status are shown, reflecting
  persisted state rather than requiring the original upload request or an open connection

#### Scenario: Resuming after an interruption
- **WHEN** the import job is interrupted partway through (e.g. a worker restart) and later
  retried
- **THEN** processing continues from the last completed portion of the file — rows already
  successfully imported are not duplicated, and rows not yet reached are still processed

#### Scenario: Live progress while the modal is open
- **WHEN** an admin has an import's progress modal open while that import is processing
- **THEN** counts and status update on their own, without a manual reload, reaching the final
  status (completed/failed) without one either

#### Scenario: Live updates require no reload, but the import history always shows the truth
- **WHEN** live updates are unavailable (e.g. the connection dropped) and the admin closes and
  reopens the progress modal, or reloads the imports page, instead
- **THEN** the reopened modal or reloaded history shows the same persisted state a live update
  would have shown — live updates are a convenience on top of the persisted state, never a
  separate source of truth

#### Scenario: Only an admin receives live updates for an import
- **WHEN** a non-admin or an unauthenticated visitor attempts to subscribe to an import's live
  updates
- **THEN** the subscription is rejected — the same authorization boundary as the imports page
  itself (any admin, not only the one who started the import)

#### Scenario: No per-row failure detail
- **WHEN** one or more rows fail (duplicate email, invalid data, or an invalid role)
- **THEN** only the aggregate failed-row count increases — no reason is persisted for any
  individual row; an admin who needs to know which rows failed and why has to fix the file and
  re-upload it

## ADDED Requirements

### Requirement: List past imports
An admin SHALL be able to see every past spreadsheet import in the system, loaded 25 at a time
(newest first) as they scroll, rather than all at once.

#### Scenario: Viewing the import history
- **WHEN** an admin visits the imports page
- **THEN** the 25 most recent imports are shown, each with its file name, status, and progress
  counts

#### Scenario: Loading more imports
- **WHEN** an admin scrolls near the bottom of the import history and more imports exist beyond
  what's currently shown
- **THEN** the next 25 imports are loaded and appended automatically, without a full page reload

#### Scenario: Opening an import's progress from the history
- **WHEN** an admin selects an import from the history
- **THEN** that import's progress modal opens, seeded from the data already shown in the
  history row, without a separate request

### Requirement: Users are associated with the import that created them
Every User created by a spreadsheet import row SHALL be associated with the specific
`SpreadsheetImport` that created it, so the origin of an imported User can be traced.

#### Scenario: User created by an import
- **WHEN** a spreadsheet import row successfully creates a User
- **THEN** that User is associated with the import that created it

#### Scenario: User not created by an import
- **WHEN** a User is created any other way (an admin invite, or, in the future, self-registration)
- **THEN** that User has no associated import
