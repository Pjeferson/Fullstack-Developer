## Context

See proposal.md for motivation. This change has no capability spec deltas (`skip_specs: true`
in `.openspec.yaml` — confirmed with the user that no capability's requirements change here;
the installed `openspec` CLI needed upgrading from 1.6.0 to 1.13.0 for this flag to actually be
recognized as a `skipped` artifact rather than a validation error, an unrelated tooling fix made
in passing).

Relevant existing state per item:

- **Coverage**: no coverage tool exists in the Gemfile at all today — the diagnostic that started
  the design-system branch flagged this explicitly ("no coverage number to cite").
- **N+1**: `Admin::UsersQuery` (`app/queries/admin/users_query.rb`) builds `User.order(...)`
  directly, no eager-loading — the exact avatar N+1 flagged in that same diagnostic, never
  fixed. `Admin::SpreadsheetImportsQuery` already hardcodes `.with_attached_file` internally
  (added in `design-system` to avoid reproducing the same bug for import filenames) — inconsistent
  with `UsersQuery` having no eager-loading at all, and inflexible (hardcoded, not something a
  future caller could opt out of or extend).
- **Comments**: this codebase's own convention (established across every branch) already favors
  rationale-heavy comments — most existing comments already explain a "why." The ones being
  removed here are the minority that just narrate the following line(s) in plain English.
- **Backend validation**: `User` validates `email_address` (presence/uniqueness/format via
  `URI::MailTo::EMAIL_REGEXP`) and `full_name` (presence); `has_secure_password` validates
  password presence. Every controller already uses strong params (`params.permit(...)`), with
  sensitive fields (`role`) structurally excluded rather than merely unvalidated. No structural
  schema-validation layer exists on top of this.
- **Frontend validation**: no schema-validation library exists; forms rely on native HTML5
  constraints (`required`, `type="email"`) plus a round trip to see backend errors (`errors.field`,
  typed `string[]` per `types/globals.d.ts`'s `InertiaConfig` override, rendered directly by
  `ui/Input`'s existing `error` prop).
- **Unused component**: `components/ui/Select.tsx` (Headless UI `Listbox`-based, built in
  `design-system` for a mockup that showed a styled dropdown) was never actually wired into any
  page — no form in this app has needed a select field yet.

## Goals / Non-Goals

**Goals:**
- A real, reported backend coverage number.
- No N+1 on the admin User list's avatar column (or the import history's filename), fixed the
  same way for both, extensibly (not hardcoded to one attachment).
- Comments that carry their weight — every one left explains something the code alone doesn't.
- A documented, defensible reason for not adding a schema-validation gem, not silence.
- Client-side validation that mirrors backend rules exactly and blocks a submission it can
  already tell is invalid, without becoming a second source of truth that could drift from the
  server.
- No dead frontend code.

**Non-Goals:**
- Actually closing the coverage gap (separate, later effort, confirmed).
- A JS test runner or tests for the new validation code — Playwright remains the next branch.
- Any change to what the backend accepts or rejects — client-side validation adds no new rules,
  it surfaces the existing ones earlier.
- A backend schema-validation layer — explicitly decided against in this change, not merely
  deferred.

## Decisions

### Query objects take a `scope:` argument instead of hardcoding eager-loading

```ruby
module Admin
  class UsersQuery
    PER_PAGE = 25

    def initialize(before_id: nil, scope: User.all)
      @before_id = before_id
      @scope = scope
    end
    # records/metadata unchanged
    private
      def fetched
        @fetched ||= begin
          scope = @scope.order(id: :desc).limit(PER_PAGE + 1)
          scope = scope.where(User.arel_table[:id].lt(before_id)) if before_id
          scope.to_a
        end
      end
  end
end
```
`Admin::UsersController#index` passes `scope: User.with_attached_avatar_image` (the macro
`has_one_attached :avatar_image` already generates this scope — no new code needed to get it).
`Admin::SpreadsheetImportsQuery` gets the identical treatment, its hardcoded
`.with_attached_file` moving out to `Admin::SpreadsheetImportsController#index` as
`scope: SpreadsheetImport.with_attached_file`.

Rejected: leaving `SpreadsheetImportsQuery`'s hardcoded eager-load as-is and only fixing
`UsersQuery` with its own hardcoded `.with_attached_avatar_image`. That would fix today's known
N+1s but leave two query objects solving the identical problem two different ways — the `scope:`
argument is the same fix applied consistently, and it means neither query object needs to know
about ActiveStorage at all; that's the caller's concern.

### Comment sweep: keep the "why", drop the restatement

No new tooling — read every comment in `app/` and `app/javascript/`, judge each on one question:
does removing it lose information the adjacent code doesn't already convey? If yes (a rejected
alternative, a trade-off, a reference to a spec/design doc, a non-obvious constraint like "must
run before X because Y"), keep it verbatim. If no (it just says what the method/line does, in
English instead of Ruby/TypeScript), remove it. `openspec/` itself is untouched — those documents
are meant to be narrative. Framework-generated comments that predate this project's own work
(Rails scaffold boilerplate in initializers, etc.) are also left alone — not this project's
writing to begin with, and not what "comments in this codebase" was raised about.

### Backend validation: document the decision, don't implement a schema layer

New README section stating plainly: validation stays at the model layer
(`ActiveModel`/`ActiveRecord` validations plus strong params), a `dry-schema`/`dry-validation`-
style structural layer was considered and deliberately not added, and this was a conscious
trade-off made with awareness of how much untrusted-input handling matters — not something that
went unconsidered. Exact wording drafted for review before being applied to `README.md`, same
process as the AI-disclosure section.

### Client-side validation: Zod schemas + a small `useValidation` hook, no react-hook-form

```ts
// app/javascript/hooks/useValidation.ts
export function useValidation<T extends Record<string, unknown>>(schema: z.ZodType<T>, data: T) {
  const [touched, setTouched] = useState<Partial<Record<keyof T, boolean>>>({})
  const result = useMemo(() => schema.safeParse(data), [schema, data])
  const errors = useMemo(() => {
    const fieldErrors: Partial<Record<keyof T, string[]>> = {}
    if (!result.success) {
      for (const issue of result.error.issues) {
        const field = issue.path[0] as keyof T
        if (touched[field]) fieldErrors[field] = [...(fieldErrors[field] ?? []), issue.message]
      }
    }
    return fieldErrors
  }, [result, touched])
  function touch(field: keyof T) { setTouched((t) => ({ ...t, [field]: true })) }
  function touchAll() {
    setTouched(Object.fromEntries(Object.keys(data).map((k) => [k, true])) as Record<keyof T, boolean>)
  }
  return { errors, isValid: result.success, touch, touchAll }
}
```
Used as `error={clientErrors.field ?? errors.field}` (client error, when present, wins; server
error fills in for anything only the server can know, e.g. email uniqueness) and
`onBlur={() => touch('field')}` (nothing shows red before the User has had a chance to type).
Submit handlers gain `if (!isValid) { touchAll(); return }` before calling `post`/`put` — the
part of the ask that isn't just "show messages," it's "many invalid scenarios never reach the
backend at all."

Rejected: react-hook-form + Zod (the most common pairing). It would replace Inertia's `useForm`
as the form's state manager across every page in the app — a much bigger change in established
pattern than "add validation," and `useForm` already handles multipart submission, CSRF, and the
`errors` prop shape this app is built around. Layering Zod directly on top of the existing
`useForm` state gets the validation without touching how forms already work.

Schemas mirror backend rules exactly (`app/javascript/schemas/`) — no invented stricter rules
(e.g. no client-only minimum password length, since the server has none either). `userFormSchema`
(full name + email) is shared by `UserForm` (admin create/edit) and, by having
`pages/profiles/show.tsx` render `UserForm` instead of its own duplicated copy of the same two
fields, by the self-service profile page too — folding in a small existing duplication while
this file is already being touched for validation.

## Risks / Trade-offs

- **[Client and server validation could drift over time]** → Mitigated by deliberately mirroring
  today's rules exactly rather than inventing independent ones, and by never treating a passing
  client check as sufficient on its own — every submission still goes through full backend
  validation regardless of what the client already checked.
- **[No automated test for the new `useValidation` hook or Zod schemas]** → Consistent with this
  branch's stated non-goal (no JS test runner yet); covered by manual verification instead, same
  as every other frontend behavior in this app until Playwright lands.
- **[`ImportUploader`'s extension check can't match the server's content-type sniff exactly]** →
  A browser can only see a file's name, not sniff its actual bytes the way
  `Imports::ParserFactory` does server-side; a `.csv`-renamed non-CSV file passes the client
  check and still gets a real backend check on upload, so this narrows the window for showing an
  error early without weakening what's actually enforced.
- **[This increment wasn't manually verified in a real browser]** → It since was, by the user -
  and that testing surfaced a real bug (a stale native file input after a successful upload), now
  fixed; see "Post-Review Increment: fix a stale native file input after a successful upload".

## Post-Review Increment: refresh the import row on modal close

**Superseded by "Post-Review Increment: restrict the progress modal to fresh uploads, reload on
close" below** - kept here for the record of what was tried and why, not as the current
behavior. Noticed during review, not part of the original six items: an import's row in
`admin/spreadsheet_imports/index.tsx`'s history table kept showing whatever it looked like when
the page/list loaded (e.g. "Pending"), even right after an admin watched it reach "Completed"
live inside `ImportProgressModal` — closing the modal left the stale row behind, since the
modal's live subscription only ever updated its own local state, never the page's `imports`.

**Local patch on close, not a server reload.** `ImportProgressModal`'s `onClose` now hands back
its last-seen `summary`; the page mirrors `imports` into local state (the same pattern
`admin/users/index.tsx` already uses for `stats` — resynced via a `useEffect` whenever the real
`imports` prop changes) and patches just the closed row with that summary. Rejected: reloading
`imports` from the server on close (`router.reload({ only: ['imports'] })`). `InertiaRails.scroll`
marks this prop `merge: true` unconditionally (see `ScrollProp#configure_merge_intent` — every
response is treated as `append` unless the request explicitly signals `prepend`), so a bare
reload would append the fetched page-1 rows on top of whatever's already loaded instead of
replacing them, visibly duplicating rows. Inertia v2 does have a `reset: string[]` visit option
for exactly this ("refetch and replace instead of merge"), but using it would also snap the
infinite-scroll list back to its first page, discarding any depth an admin had already scrolled
to — an acceptable cost for some apps, but avoidable here entirely by not calling the server at
all, since the modal already held the answer.

## Post-Review Increment: client-side validation on the import upload field

Noticed while reviewing item 6 in this same change: every other required field in the app
(sign-in, registration, forgot/reset password, `UserForm`) got a Zod schema in that item, but
`ImportUploader`'s file input didn't - it's a required field too, still relying on native HTML5
`required` alone plus a full request round trip to surface `"can't be blank"` or `"must be a CSV
or XLSX file"` from `Admin::SpreadsheetImportsController#create`.

`importUploadSchema` (`app/javascript/schemas/index.ts`) mirrors that controller's own checks, in
the same order it makes them - presence first, then format against
`Imports::ParserFactory`'s supported extensions (`.csv`/`.xlsx`):

```ts
const importFile = z
  .instanceof(File, { error: "can't be blank" })
  .refine((file) => /\.(csv|xlsx)$/i.test(file.name), { error: 'must be a CSV or XLSX file' })

export const importUploadSchema = z.object({ file: importFile })
```

`z.instanceof(File)` rejects `null` (nothing selected yet) with the custom "can't be blank"
message directly - confirmed by hand that this doesn't also throw or emit a second issue when
`file` is `null`, since the refine step never runs once the base type check has already failed.
The extension check here is necessarily looser than the server's, which sniffs the uploaded
bytes' content-type rather than trusting a filename - a browser can't do that, so a `.csv`-named
file still gets a full backend check regardless of what the client already accepted.

`useForm`'s `data.file` is typed `File | null` (a fresh form has no file yet), while the schema's
output is `File` (a valid submission always has one) - `ImportUploader.tsx` casts the value at
the `useValidation` call site to bridge that gap; the cast doesn't change what's actually
validated, `z.instanceof` still rejects a real `null` at runtime exactly as before.

Wired the same way as every other form in this change: `onBlur={() => touch('file')}`,
`clientErrors.file?.[0] ?? errors.file`, and the submit handler gains
`if (!isValid) { touchAll(); return }` ahead of `post(...)`.

**Left unverified in a real browser for this increment** - `npm run check` and `bin/rails test`
both stayed clean, but the user asked to test this one manually themselves rather than have it
checked here.

## Post-Review Increment: fix a stale native file input after a successful upload

Found by the user manually testing the increment above: uploads intermittently appeared to fail
instantly with `"can't be blank"`, processing nothing.

Root cause: `<input type="file">` is uncontrolled - `reset()` in `ImportUploader`'s `onSuccess`
only clears Inertia's `data.file` state, it has no way to touch the native input's own value
(React can't set a file input's `value` at all, for security reasons browsers enforce). After a
successful upload, the browser's file picker kept visually showing the previous filename while
`data.file` was already `null` again internally - a mismatch invisible to the admin. Attempting a
second upload without reselecting a file then failed immediately: the previous increment's client
check (correctly) caught the null `data.file` and blocked the submission before a request even
went out, but the underlying state mismatch predates that check and would have produced the same
outcome via a real round trip before it existed too.

Fix: a `ref` on the file input; `onSuccess` now also sets `fileInputRef.current.value = ''`
alongside `reset()`, so the native picker's displayed state and the form's actual state can't
drift apart again.

## Post-Review Increment: restrict the progress modal to fresh uploads, reload on close

Revised in conversation, replacing the "refresh the import row on modal close" increment above.
The premise there was that the progress modal could be opened from any row in the history table,
so closing it had to patch whatever row was open without disturbing the admin's scroll position.
Reconsidered: a past import's row already shows everything the modal would (status, progress,
succeeded/failed counts) - there was never a real use case for reopening it after the fact, only
for watching a just-started one live. So `onSelect` came out of `ImportRow`, `ImportCard`, and
`ImportHistoryTable` entirely; `admin/spreadsheet_imports/index.tsx` only ever sets
`selectedImport` from `handleUploaded`, right after a fresh upload.

That constraint removes the reason the local-patch approach existed. The modal now only ever
shows the import that was *just* created, which - given the newest-first ordering - is always
sitting at the very top of the history, i.e. exactly what page 1 of it already contains. Closing
the modal can safely reload from the server and land back on page 1, since that's not a loss of
position at all in this scenario:

```ts
router.reload({ only: [ 'imports' ], reset: [ 'imports' ] })
```

`reset` (not just `only`) is what makes this safe rather than duplicating rows - confirmed by
reading `inertia_rails`'s `props_resolver.rb`: the client sends an `X-Inertia-Reset` header
listing this prop, the server checks `reset_keys.include?(path)` and marks that prop's scroll
metadata `reset: true` instead of the usual merge/append markers, so `InertiaRails.scroll` sends
`imports` back as a plain replacement rather than another page to append. `ImportProgressModal`'s
`onClose` reverts to a plain `() => void` - it no longer needs to hand back its last-seen
`summary` for a caller to patch locally.

## Post-Review Increment: two more Deliberate Implementation Decisions entries

Requested directly by the user: two more entries for the README section added in item 5 (renamed
along the way from "Implementation Decisions" to "Deliberate Implementation Decisions", per their
own preference for the title), documenting decisions this codebase already reflects but had
never written down:

- **Explicit side effects over model callbacks** — `Imports::ProgressBroadcaster` and
  `Dashboard::StatsBroadcaster` are called explicitly from the job/controller that changes state,
  never from an `after_save`/`after_update_commit` callback (see the `import-progress` and
  `dashboard-realtime` archived changes, which made this call originally). First drafted with a
  sentence narrating that a callback was tried and dropped for the import broadcaster
  specifically - removed on the user's feedback that this read oddly; the final wording states
  the decision and its reasoning directly, without the "first draft was X" framing.
- **Simple, hand-rolled JSON over a serialization layer** — every JSON shape in this app
  (`profile_json`, `summary_json`, `users_json`, `imports_json`) is a plain `as_json`, no
  serialization gem in use despite `jbuilder` sitting unused in the `Gemfile`. First drafted with
  an explicit "this wasn't a knowledge gap" disclaimer (mirroring the Input Validation entry's
  own framing) - removed on the user's feedback that it read as unnecessarily defensive here;
  the final wording simply notes that a production app of larger scope would reach for a
  dedicated tool (`Blueprinter` or similar) instead, without denying a knowledge gap that wasn't
  raised as a question in the first place.

Both entries were drafted and shown for review before being applied, same process as every prior
README addition in this project.

## Migration Plan

No schema/data migrations. All changes are additive tooling (SimpleCov, Zod), refactors with
identical external behavior (query `scope:` argument, comment removal), or documentation. Rollback
for any item is a plain revert.
