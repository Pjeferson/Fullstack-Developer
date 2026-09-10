## 1. Tooling setup

- [x] 1.1 `Gemfile`, `:test` group: replace `gem "selenium-webdriver"` with
  `gem "capybara-playwright-driver"`; `bundle install`
- [x] 1.2 `package.json`: `npm install --save-dev playwright@<version matching
  Playwright::COMPATIBLE_PLAYWRIGHT_VERSION>`
- [x] 1.3 `npx playwright install chromium`; confirm a headless launch actually works in this
  sandbox (smoke-tested directly via `Playwright.create`, not just installed)
- [x] 1.4 `test/application_system_test_case.rb`: register the `:playwright` driver
  (chromium, headless by default, `HEADLESS=false` to override), `driven_by :playwright`,
  `include ActiveJob::TestHelper` (needed for `perform_enqueued_jobs` - not pulled in by
  `ActionDispatch::SystemTestCase` on its own), and a shared `settle_after_fill!` helper (see
  "Post-implementation findings" in design.md for why)
- [x] 1.5 `ApplicationSystemTestCase` switches Action Cable to `async` for its own tests only, via
  a `setup` block calling `ActionCable::Server::Base`'s public `config`/`restart` API -
  `config/cable.yml` stays on Rails' default (`test`) unchanged. Revised from a first draft that
  changed `cable.yml` globally: measured no cost to the rest of the suite either way (every
  broadcast-triggering test already uses `ActionCable::TestHelper`, which overrides regardless of
  `cable.yml`), but scoped it anyway on review — see design.md

## 2. Shared system-test infrastructure

- [x] 2.1 `test/test_helpers/system_test_authentication_helper.rb`: `sign_in_as(user, password:)`
  driving the real sign-in form (`visit new_session_path`, fill, submit) — included into
  `ActionDispatch::SystemTestCase` via `ActiveSupport.on_load`; waits for the post-sign-in
  redirect to actually land before returning (see design.md)
- [x] 2.2 Verified the whole pipeline (driver, Puma server, DB, fixtures) end to end with a
  throwaway smoke test before writing the real specs, then deleted it - superseded by
  `sessions_test.rb`

## 3. `test/system/sessions_test.rb`

- [x] 3.1 Valid admin credentials redirect to `/admin/users`
- [x] 3.2 Valid non-admin credentials redirect to `/profile`
- [x] 3.3 Invalid credentials show an inline error, stay on the sign-in page - this is what
  surfaced the real flash-sharing bug fixed in `InertiaController` (see design.md)
- [x] 3.4 "Sign up"/"Forgot your password?" links navigate to the right pages - this is what
  surfaced the autofocus/blur mid-click reflow finding (see design.md)

## 4. `test/system/registrations_test.rb`

- [x] 4.1 A visitor can register with name/email/password and lands on `/profile`
- [x] 4.2 The created User has `role: "default"` (never settable from this form)
- [x] 4.3 Invalid input (a taken email) shows an error, creates no User

## 5. `test/system/passwords_test.rb`

- [x] 5.1 Requesting a reset for a real email, wrapped in `perform_enqueued_jobs`, actually sends
  one email (`ActionMailer::Base.deliveries`) and redirects to sign-in with a generic notice
- [x] 5.2 Visiting the reset link (`edit_password_path(user.password_reset_token)`), submitting a
  new password + matching confirmation allows sign-in with the new password
- [x] 5.3 A mismatched confirmation is caught client-side (`passwordsEditSchema`'s `.refine`) and
  never reaches the server - revised from the original plan, which assumed the server-side
  message would be what's seen (see design.md)
- [x] 5.4 An invalid/expired token redirects with an error instead of rendering the reset form

## 6. `test/system/admin/users_test.rb`

- [x] 6.1 Signed in as admin: the user list renders with existing fixture Users
- [x] 6.2 Create (invite) a new User via the modal; it appears in the list
- [x] 6.3 Edit a User's name/email via the modal; the row reflects it
- [x] 6.4 Promote a default User to admin and demote them back; `RoleBadge` reflects each state
- [x] 6.5 Delete a User via the confirm dialog; it's removed from the list
- [x] 6.6 A non-admin visiting `/admin/users` is redirected away, never sees the page

## 7. `test/system/admin/spreadsheet_imports_test.rb`

- [x] 7.1 Uploading `valid.csv`, wrapped in `perform_enqueued_jobs`, opens the progress modal
  automatically and it reaches "Completed" (real WebSocket delivery, not a poll/reload)
- [x] 7.2 Closing the modal reloads the history and the row shows the finished import (see
  `chore/quality-hardening`'s modal-restriction/reload-on-close increment - this is that flow)
- [x] 7.3 The imported rows actually created new Users (spot-check via `User.where`)
- [x] 7.4 Uploading an unsupported file type shows the client-side validation error, never
  reaches the server (no new `SpreadsheetImport` row created)

## 8. `test/system/profiles_test.rb`

- [x] 8.1 Signed in as a non-admin: `/profile` shows their own name, editable
- [x] 8.2 Editing full name via the form persists and re-renders the new value
- [x] 8.3 Deleting their own account via the confirm dialog signs them out, back at sign-in

## 9. A real bug found along the way: flash never reached the frontend

- [x] 9.1 `sessions_test.rb`'s invalid-credentials test kept failing to find the expected error
  text on screen, despite the server correctly redirecting with `alert:` set - traced to
  `InertiaController#inertia_share` never exposing plain Rails `flash[:notice]`/`flash[:alert]`
  as a prop, only `current_user` (`usePage().props.flash` was always `undefined`)
- [x] 9.2 Confirmed with the user before fixing (this was a scope question, not just a bug) -
  chose to fix now rather than defer
- [x] 9.3 `InertiaController#inertia_share` now also shares `flash: { notice:, alert: }`; fixes
  10 previously-silent messages across `sessions/new`, `passwords/new`, `passwords/edit`
- [x] 9.4 `bin/rails test test/controllers` stays green (no controller test ever asserted on the
  rendered flash text, so nothing was accidentally relying on the old, broken behavior)

## 10. Final verification

- [x] 10.1 `bin/rails test:system` (system tests are excluded from plain `bin/rails test` by
  Rails' own default) — 16 runs, green, headless, stable across repeated runs
- [x] 10.2 `bin/rails test` — the rest of the suite (159 runs) stays green, 100.00% line coverage
- [x] 10.3 `npm run check` / `bin/rubocop` / `bin/brakeman` — clean
- [x] 10.4 README: new "System tests (Playwright)" section (`bin/rails test:system`, the one-time
  `npx playwright install chromium` step, `HEADLESS=false`, a note about `--with-deps`)

## 11. Post-review: cross-browser support (Chromium, Firefox, WebKit)

- [x] 11.1 `npx playwright install firefox webkit` - both installed despite a missing-shared-libs
  warning in this sandbox (see design.md's Risks)
- [x] 11.2 `test/application_system_test_case.rb`: `browser_type:` now reads `ENV["BROWSER"]`
  (default `chromium`) instead of hardcoding `:chromium`
- [x] 11.3 Verified for real: full 16-test suite, twice each, green on chromium, firefox, and
  webkit - no timing/`settle_after_fill!` changes needed
- [x] 11.4 README: `npx playwright install` (all three, no longer chromium-only), `BROWSER=...`
  usage for each engine
