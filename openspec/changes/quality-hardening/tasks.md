## 1. Coverage measurement

- [x] 1.1 Add `gem "simplecov", require: false` to the `:test` group in `Gemfile`;
  `require "simplecov"; SimpleCov.start "rails"` as the first lines of `test/test_helper.rb`
  (before `require_relative "../config/environment"`); confirm `/coverage/` is gitignored
- [x] 1.2 Run `bin/rails test`, report the resulting line-coverage percentage in chat (no attempt
  to close gaps this branch)

## 2. Comment sweep

- [x] 2.1 Sweep `app/` (controllers, models, services, queries, jobs, channels, mailers):
  remove comments that only restate the adjacent code; keep ones explaining a decision,
  trade-off, rejected alternative, or non-obvious constraint
- [x] 2.2 Sweep `app/javascript/` (components, pages, hooks, types) the same way
- [x] 2.3 Run `bin/rails test` and `npm run check` — both clean (no behavior change expected)

## 3. Remove unused component

- [x] 3.1 Delete `app/javascript/components/ui/Select.tsx` (confirmed 0 references)
- [x] 3.2 Run `npm run check` — clean

## 4. Fix admin list N+1s

- [x] 4.1 `Admin::UsersQuery` and `Admin::SpreadsheetImportsQuery`: accept `scope:` in the
  constructor (defaulting to `User.all`/`SpreadsheetImport.all`), use it as the base of `fetched`
  instead of a hardcoded/absent scope
- [x] 4.2 `Admin::UsersController#index` passes `scope: User.with_attached_avatar_image`;
  `Admin::SpreadsheetImportsController#index` passes `scope: SpreadsheetImport.with_attached_file`
  (moved out of the query object, where it was hardcoded)
- [x] 4.3 Add a regression test to each controller test (`admin/users_controller_test.rb`,
  `admin/spreadsheet_imports_controller_test.rb`): create several records with attachments,
  subscribe to `sql.active_record` notifications, assert the attachment-table query count stays
  flat (≈1-2) regardless of row count
- [x] 4.4 Run `bin/rails test` — full suite green

## 5. Document the backend-validation decision

- [x] 5.1 Draft the README section wording, show it for review before applying (same process as
  the AI-disclosure section)
- [x] 5.2 Apply it to `README.md` once approved

## 6. Client-side schema validation (Zod)

- [x] 6.1 Add `zod` to `package.json`
- [x] 6.2 Add `app/javascript/schemas/` (fullName/email/password primitives; `userFormSchema`,
  `registrationSchema`, `sessionSchema`, `passwordsNewSchema`, `passwordsEditSchema` composed
  from them) mirroring backend rules exactly — no invented stricter rules
- [x] 6.3 Add `app/javascript/hooks/useValidation.ts` (`useValidation(schema, data)` →
  `{ errors, isValid, touch, touchAll }`)
- [x] 6.4 Wire into `pages/sessions/new.tsx`, `pages/registrations/new.tsx`,
  `pages/passwords/{new,edit}.tsx`: `onBlur={() => touch('field')}`,
  `error={clientErrors.field ?? errors.field}`, submit handler gains
  `if (!isValid) { touchAll(); return }` before `post`/`put`
- [x] 6.5 Wire the same into `components/users/UserForm.tsx` (touch/errors as props from its
  caller, `UserModal`, which owns the `useValidation` call alongside its existing `useForm`)
- [x] 6.6 Rewrite `pages/profiles/show.tsx` to render `UserForm` instead of its own duplicated
  full-name/email fields, wiring its own `useValidation(userFormSchema, data)` the same way
  `UserModal` does
- [x] 6.7 Run `bin/rails test` and `npm run check` — both clean

## 7. Final verification

- [ ] 7.1 Run `bin/rubocop` and `bin/brakeman` — no new offenses
- [ ] 7.2 Manual check via a real browser: admin User list with several avatars loads with a
  flat attachment-query count (checked via Rails log); registration/login/password/profile forms
  show inline errors as fields are blurred and block submission until fixed; a server-only error
  (duplicate email) still appears correctly after submitting
