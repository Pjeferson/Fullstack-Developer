## Why

Every capability in this app (auth, admin User CRUD, spreadsheet import, self-service profile)
already has backend coverage (100% line coverage via Minitest, `chore/quality-hardening`) but
nothing exercises the real browser: React rendering, client-side validation, live Action Cable
updates, and the actual click-through flow a user experiences. This was flagged repeatedly as
the next branch throughout this project and is requested directly now. No capability spec deltas
— this adds test coverage for behavior the specs already describe, it doesn't change or add any
(`skip_specs: true`).

## What Changes

- Adds Playwright as the browser driver for Rails' own `ActionDispatch::SystemTestCase`, via the
  `capybara-playwright-driver` gem (Ruby-side integration, confirmed with the user over
  `@playwright/test`) — replaces the unused `selenium-webdriver` gem, which was never wired to an
  actual `test/system/` directory.
- Adds the `playwright` npm package (pinned to the exact version `playwright-ruby-client`
  expects) as a devDependency, plus all three browser engines it drives (Chromium, Firefox,
  WebKit).
- `ApplicationSystemTestCase` switches Action Cable to the `async` adapter (a real, in-process
  pub/sub a browser's actual WebSocket connection can receive from) for the duration of each
  system test, via `ActionCable::Server::Base`'s own public `config`/`restart` API — necessary
  for system tests to observe live updates (import progress, dashboard stats) the way a real user
  would. `config/cable.yml` itself stays on Rails' own default (`test`, built for
  `assert_broadcast_on`/`assert_has_stream`) rather than changing file-wide for a switch only
  system tests need — see design.md for why a global config change was tried first and reverted.
- 6 system test files under `test/system/`, one per page/flow as requested: sign-in, visitor
  registration, forgot/reset password (one file — both pages, one continuous journey), the full
  admin User CRUD flow, the full spreadsheet import flow (upload → live progress → history), and
  the self-service profile flow (view/edit/delete own account).
- A new `SystemTestAuthenticationHelper#sign_in_as(user)` for system tests — drives the real
  sign-in form through the browser (the existing controller-test `sign_in_as`, which reaches into
  Rails' internal test cookie jar, doesn't work here: a real external browser has its own cookie
  jar, reachable only through an actual request/response cycle).
- **Found and fixed along the way, confirmed with the user before fixing**: `flash[:notice]`/
  `flash[:alert]` were never actually shared to the frontend — `InertiaController#inertia_share`
  only exposed `current_user`. 10 flash messages across sign-in, forgot/reset password had
  silently never rendered, for any user, ever; no existing test asserted on the rendered text to
  catch it. See design.md's "Post-Implementation Findings" for the full trace and fix.
- **Added on review**: cross-browser support. `BROWSER` env var (`chromium`/`firefox`/`webkit`,
  defaulting to `chromium`) selects which engine `ApplicationSystemTestCase`'s driver launches —
  the full 16-test suite is verified green on all three (twice each, for stability).

## Out of scope

- Running these in CI (no CI pipeline exists yet in this repo) — this change only makes the suite
  runnable locally via `bin/rails test:system` (system tests are excluded from plain
  `bin/rails test` by Rails' own default).
- Visual regression / screenshot-diffing.

## Capabilities

### New Capabilities
None — test coverage for existing, already-specified behavior.

### Modified Capabilities
None — `skip_specs: true`; see design.md for the full rationale on each decision instead.

## Impact

- **Gemfile**: `capybara-playwright-driver` replaces `selenium-webdriver` in the `:test` group.
- **package.json**: `playwright` devDependency, pinned.
- **config/cable.yml**: unchanged — the `async` switch is scoped to `ApplicationSystemTestCase`
  at runtime instead (see design.md).
- **New**: `test/application_system_test_case.rb`, `test/test_helpers/
  system_test_authentication_helper.rb`, `test/system/{sessions,registrations,passwords,
  profiles}_test.rb`, `test/system/admin/{users,spreadsheet_imports}_test.rb`.
- **`app/controllers/inertia_controller.rb`**: `inertia_share` now also shares `flash`.
- **README**: a new section on running system tests (browser install step, `HEADLESS` env var).
