## MODIFIED Requirements

### Requirement: Import progress is persisted and resumable
The state of an import (how many rows are expected, how many have been processed, how many
succeeded or failed) SHALL be persisted so it survives a page refresh, and SHALL allow the
import to resume from where it stopped if interrupted, without duplicating Users or re-emailing
anyone already processed. While an import is processing, an admin viewing its status page SHALL
see its counts and status update live, without needing to manually refresh.

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
- **WHEN** an admin has an import's status page open while that import is processing
- **THEN** counts and status update on their own, without a manual reload, reaching the final
  status (completed/failed) without one either — note: kept under this scenario's original
  name for traceability against the baseline spec, but the behavior is now the opposite of what
  the name says: live updates are no longer a separate capability, they're described right here

#### Scenario: Live updates require no reload, but a reload always shows the truth
- **WHEN** live updates are unavailable (e.g. the connection dropped) and the admin reloads the
  page instead
- **THEN** the reloaded page shows the same persisted state a live update would have shown —
  live updates are a convenience on top of the persisted state, never a separate source of truth

#### Scenario: Only an admin receives live updates for an import
- **WHEN** a non-admin or an unauthenticated visitor attempts to subscribe to an import's live
  updates
- **THEN** the subscription is rejected — the same authorization boundary as the status page
  itself (any admin, not only the one who started the import)

#### Scenario: No per-row failure detail
- **WHEN** one or more rows fail (duplicate email, invalid data, or an invalid role)
- **THEN** only the aggregate failed-row count increases — no reason is persisted for any
  individual row; an admin who needs to know which rows failed and why has to fix the file and
  re-upload it
