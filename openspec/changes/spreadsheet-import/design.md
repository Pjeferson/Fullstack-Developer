## Context

See proposal.md for motivation. This design follows the architecture handed to me for this
feature, adjusted in a few places to match conventions already established in this codebase
(called out explicitly under Decisions, so they're easy to challenge). `User`'s actual schema:
`email_address` (not `email`), `full_name`, `password_digest`, `role` (`default`/`admin`, enum
default `default`), unique index `index_users_on_email_address`. Ruby 4.0 no longer ships `csv`
as a default gem, so it needs declaring like any other dependency.

## Goals / Non-Goals

**Goals:**
- Upload a CSV/XLSX file, process it as background batches without blocking the request or
  loading the whole file into memory at once.
- Survive a worker restart mid-import without duplicating Users or losing progress.
- Reuse existing pieces (`AttachRemoteAvatarJob`, its SSRF protections) instead of duplicating
  them for the per-row avatar case.

**Non-Goals:**
- Live/streaming progress UI (Action Cable broadcast) — per the project roadmap this is
  `feature/import-progress`, a separate later branch with a hard dependency on this one. This
  branch only has to persist state in a shape that branch can broadcast; it does not add a
  channel or any JS subscription.
- Per-row failure detail. Only aggregate counts (`processed_rows`, `success_count`,
  `error_count`) are persisted — no `row_errors` list and no per-row table. An admin sees *how
  many* rows failed, not *why* each one did. Confirmed with the user as unnecessary for this
  branch; revisit only if a real need for per-row diagnosis shows up later.
- Editing/retrying individual failed rows from the UI — a failed row is reported, not corrected,
  in this branch.

## Decisions

### Parser: one shared interface for CSV and XLSX

Both formats are read through the same contract so the job never branches on file type:

```ruby
module Imports
  module Parser
    def each_row  = raise NotImplementedError # yields a Hash per data row; no block -> Enumerator
    def row_count = raise NotImplementedError
  end
end
```

Both parsers take a plain local file **path** (a string), not an ActiveStorage attachment —
this keeps them decoupled from ActiveStorage and trivially unit-testable against fixture files
on disk. `Imports::CsvParser` uses Ruby's `CSV.foreach(path, headers: true)`, yielding
`row.to_h`. `Imports::XlsxParser` uses `roo`'s `each_row_streaming` (never loads the whole sheet
into memory), captures the first row as headers, and zips each subsequent row's cell values
against them so its output hash shape matches the CSV parser's exactly.

`each_row` returns `enum_for(:each_row)` when called without a block, so the job can call
`parser.each_row.each_slice(BATCH_SIZE)` — `each_slice` needs an `Enumerator`, and a plain
"only accepts a block" method raises `LocalJumpError` there. This stays memory-safe: the
`Enumerator` is fiber-backed and lazy, so the file is still read one row at a time; the batching
just groups yields before the job acts on them, never materializing the full file as an array.
The job is the one place that bridges to ActiveStorage: it wraps the whole batching loop in
`import.file.open { |tempfile| ... }`, so the downloaded/local blob file stays on disk for
exactly as long as the enumerator needs it, and hands `tempfile.path` to the parser.

`Imports::ParserFactory.for(content_type:, filename:, path:)` selects the parser by
content-type, falling back to the filename extension when the content-type is generic
(`text/plain`, `application/octet-stream` — common for a CSV exported by some spreadsheet
tools), and raises `Imports::UnsupportedFormatError` otherwise. This is a selection/factory, not
an action, so it stays a class method (`.for`, not `.new(...).call`) — consistent with how this
differs from an action service like
`Users::Inviter`.

### Row validation is its own service, deliberately separate from `User`'s validations

`insert_all` skips ActiveRecord validations and callbacks entirely — it's a raw multi-row SQL
`INSERT`, not `User.new(...).save`. That has a consequence beyond just "no automatic checks":
a Postgres multi-row `INSERT` is one atomic statement, so a `NOT NULL` violation on **any**
single row (a blank `email_address`/`full_name`) aborts the *entire* batch of 500, not just that
row — unlike a unique-index conflict, which Postgres can skip row-by-row via `ON CONFLICT`. So
malformed rows still have to be filtered out before the batch is ever sent to `insert_all`, or
one bad row silently kills 499 good ones in the same batch.

This pre-check is `app/services/imports/row_validator.rb` — a small, dedicated object, not a
reuse of `User`'s own `validates` declarations:

```ruby
module Imports
  class RowValidator
    def initialize(row) = @row = row

    def valid? = errors.empty?

    def errors
      @errors ||= begin
        errs = []
        errs << "email is invalid" unless email.match?(URI::MailTo::EMAIL_REGEXP)
        errs << "full name can't be blank" if full_name.blank?
        errs << "role is invalid" unless valid_role?
        errs
      end
    end

    private
      attr_reader :row

      def email       = row["email_address"].to_s.strip.downcase
      def full_name   = row["full_name"].to_s.strip
      def role        = row["role"].to_s.strip
      def valid_role? = role.blank? || User.roles.key?(role)
  end
end
```

Why a dedicated validator instead of reusing `User`'s model validations (e.g. via
`User.new(...).valid?`): the model's presence/format validations aren't reusable as-is here,
because `has_secure_password` bakes its own "password must be present on a new record" check
directly into the macro — not a separate `validates` line, so it cannot be scoped off with a
later `validates :password, ..., unless: ...` in the model (`validates` calls only ever add
rules, they never replace one already registered). Building a real `User.new(...)` for this
check would always fail on the password check alone, and the two workarounds for that
(monkeying with the model's validations, or attaching a throwaway `password_digest` just to
satisfy that one check) both couple import-only concerns into `User` or into a fragile
AR-instantiation trick. `Imports::RowValidator` sidesteps this by not touching AR validation
machinery at all — it checks the same underlying rules (email format, full name presence, valid
role) as plain Ruby, against the raw row hash, with no `User` instance involved. This also keeps
insertion rules (batching, the shared password digest, `insert_all`) and per-row correctness
rules in two separate, independently testable files, rather than one service doing both.

`Imports::UserBatchInserter` then does, per batch:

1. **Validate.** Partition the batch's rows via `Imports::RowValidator#valid?`; invalid rows
   never reach `insert_all` and only count toward `error_count` — their `#errors` messages exist
   for the validator's own tests, not for persistence (no per-row reason is stored; see
   Non-Goals).
2. **Password.** For the rows that passed, generate a single random, valid bcrypt hash **once
   per batch** (not once per row — bcrypt is deliberately slow, ~200-300ms, which would erase
   the point of batching at 500 hashes/batch; not once for the whole job either, since every
   User sharing one digest across the entire file is an unnecessary audit smell even though it
   isn't practically exploitable) and write it directly as `password_digest`. This mirrors
   `Users::Inviter`'s existing "random password, never usable, forces a password reset"
   approach — same semantics, computed to survive batch insertion.
3. **Role.** Each valid row's `role` column (already confirmed to be blank or a real enum key by
   `RowValidator`) is looked up via `User.roles.fetch(role, "default")` — never assigned to a
   `User` instance from raw input, so there's no risk of Rails' enum `ArgumentError` on an
   unrecognized value reaching this step at all (that path is already excluded by validation).
   Reading `role` here is a deliberate, narrow exception to admin-user-management's "role only
   changes through the dedicated role action" rule (see the delta on that capability), so
   imported/seed data can include admins to exercise the later live-dashboard-by-role feature.
4. **Insert.** `insert_all(attributes, returning: [:id, :email_address], unique_by:
   :index_users_on_email_address)`, which compiles to `ON CONFLICT (email_address) DO NOTHING`.
   Diffing the rows sent against `result.rows` (the ones actually inserted) identifies which
   rows were duplicates — against existing Users or against another row earlier in the same
   file — with no extra query and no need to preload existing emails (which would scale with the
   existing table, not the file).

So, concretely: duplicate-email detection is the one thing left entirely to `insert_all`'s
conflict resolution (by design — a query-free, single-round-trip check); everything else
structural about a row (format, presence, role membership) is decided by
`Imports::RowValidator` before a row is ever considered for insertion.

### Persisted state and resume

```ruby
create_table :spreadsheet_imports do |t|
  t.references :admin, null: false, foreign_key: { to_table: :users }
  t.string :status, null: false, default: "pending" # pending, processing, completed, failed
  t.integer :total_rows
  t.integer :processed_rows, null: false, default: 0
  t.integer :success_count, null: false, default: 0
  t.integer :error_count, null: false, default: 0
  t.integer :last_completed_batch, null: false, default: 0
  t.datetime :started_at
  t.datetime :finished_at
  t.timestamps
end
```

The job checkpoints `last_completed_batch` after each batch. `insert_all`'s `ON CONFLICT DO
NOTHING` already makes a batch idempotent — if Solid Queue retries the job (worker restart,
dropped DB connection), re-running an already-completed batch just re-hits the conflict clause
and inserts nothing new. So resume only needs batch-level granularity (skip batches below the
checkpoint before touching the DB again), not a per-row cursor.

The Inertia page for an import reads this record as a normal prop on load/refresh — no
Action Cable involved in this branch (see Non-Goals).

### Avatar-by-URL stays a separate, per-user async job

`insert_all` never touches ActiveStorage. When a successfully-inserted row includes an avatar
URL, the existing `AttachRemoteAvatarJob.perform_later(user_id, url)` is enqueued using the id
`insert_all`'s `returning:` gives back — so a duplicate row discarded by the conflict clause
never triggers a wasted download, and one row's slow/broken avatar URL never blocks the import
job's progress through later batches (each avatar job is independent).

## Risks / Trade-offs

- **[Large file, single upload request]** → the file itself is uploaded synchronously (Rails
  already handles this as a normal multipart upload); only *processing* is async. A size cap on
  the upload (e.g. rejecting a spreadsheet claiming an unreasonable row count upfront) is worth
  a follow-up but isn't a correctness issue for this branch.
- **[No per-row failure reason]** → confirmed with the user: this branch does not persist why
  each row failed, only the aggregate `error_count`. Chosen deliberately over the earlier idea
  of an unbounded `row_errors` JSON array (which would have grown without limit on a very bad
  file) — not by capping that list, but by not building it at all. An admin who needs to know
  which rows failed and why has to fix the file and re-upload, or (later, out of scope here)
  this can grow into a real per-row report.
- **[Batch-level resume re-parses skipped batches]** → this is a deliberate simplification, not
  an oversight: resuming skips *inserting* already-completed batches (via the
  `last_completed_batch` checkpoint), but still *parses* the file from the beginning up to that
  point, because skipping happens in the parser's iteration, not before it. Chosen over a
  byte/row cursor because parsing is far cheaper than inserting, and a cursor would need a
  genuinely different implementation per format (a CSV byte offset vs. an XLSX row index via
  `roo`'s streaming reader aren't the same kind of "position" — the payoff for that complexity
  isn't there while restarts are expected to be rare and files aren't huge). If resumed imports
  turn out to matter on large files, a per-format cursor is the natural follow-up.

## Migration Plan

Purely additive: one new table, no changes to existing tables or models. No backfill. Rollout
is a normal migrate; rollback is dropping the new table (no other code depends on it).
