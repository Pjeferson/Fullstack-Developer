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

## Migration Plan

No schema/data migrations. All changes are additive tooling (SimpleCov, Zod), refactors with
identical external behavior (query `scope:` argument, comment removal), or documentation. Rollback
for any item is a plain revert.
