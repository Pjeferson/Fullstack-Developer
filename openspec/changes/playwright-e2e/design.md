## Context

See proposal.md for motivation. Two tooling questions were confirmed directly with the user
before building anything:

1. **Driver**: `playwright-ruby-client`/`capybara-playwright-driver` (Ruby, integrates with
   `ActionDispatch::SystemTestCase`) over `@playwright/test` (Node's own official test runner).
   The user's own pick, not the recommendation offered (`@playwright/test`) — this keeps system
   tests inside Minitest, the one test framework this whole project already standardizes on,
   rather than adding a second, JS-native test runner with its own config/reporting/CI story.
2. **Background job execution during the import system test**: `perform_enqueued_jobs` (runs the
   job inline, synchronously, right after the triggering browser action) over a real
   `SolidQueue::Worker` thread. The trade-off: the browser will see the import jump straight to
   "Completed" rather than observing genuine incremental progress mid-test. Accepted — the test
   still exercises the real job, the real `Imports::ProgressBroadcaster`, and a real WebSocket
   delivery to the browser; it just doesn't pace that delivery out mid-test the way production
   does. Simpler, no worker-thread lifecycle to manage or leak between tests.

## Goals / Non-Goals

**Goals:**
- A real browser (Chromium via Playwright) exercising every page this app has, through
  `ActionDispatch::SystemTestCase` — same `bin/rails test` entry point as every other test here.
- Live Action Cable updates actually observable by the browser during a system test (not just
  assertable via `ActionCable::TestHelper`, which is already covered by existing channel tests).
- One file per page/flow, matching how the user described the plan.

**Non-Goals:**
- CI wiring (no pipeline exists yet).
- Multi-browser coverage.
- Replacing or duplicating existing Minitest controller/model/job coverage — these tests check
  what a real user sees and clicks, not business-rule edge cases already covered elsewhere.

## Decisions

### `capybara-playwright-driver`, replacing the unused `selenium-webdriver`

```ruby
# Gemfile, :test group
gem "capybara"
gem "capybara-playwright-driver"
```

Pulls in `playwright-ruby-client` (1.62.0, resolved by Bundler) transitively. This gem drives a
*real* browser process (`needs_server? # => true`) that talks to Capybara's Puma server over
actual HTTP/WebSocket — the same threading model Rails' default Selenium-based system tests use,
so transactional fixtures work exactly as they do for every other test in this suite (the Puma
server runs in a background thread of the *same* process as the test, sharing the DB connection
pool — nothing system-test-specific needed here).

The Playwright browser binaries are driven through the Node `playwright` package, not bundled in
the Ruby gem — `playwright-ruby-client` shells out to it. Pinned in `package.json` to the exact
version the resolved gem expects (`Playwright::COMPATIBLE_PLAYWRIGHT_VERSION`, currently
`1.62.1`) rather than "latest", since a mismatch between the Ruby client's expected protocol
version and the actual driver binary is a real (if usually minor) compatibility risk documented
by the gem itself.

```ruby
# test/application_system_test_case.rb
require "test_helper"
require "capybara/playwright"

Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium,
    headless: ENV["HEADLESS"] != "false", # HEADLESS=false to watch it run locally
    playwright_cli_executable_path: Rails.root.join("node_modules/.bin/playwright").to_s
  )
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :playwright
end
```

`playwright_cli_executable_path` points at the local `node_modules/.bin/playwright` explicitly
rather than the gem's own default (`npx playwright`) — avoids `npx`'s own resolution/download
prompt overhead on every browser launch, and pins exactly which install runs.

**Browser binaries**: `npx playwright install chromium` (no `--with-deps` — this sandbox has no
passwordless `sudo`, so the OS-level dependency install step had to be skipped; the binary itself
still installs and runs headless correctly here, since the underlying libraries already happen to
be present). A real CI environment or a fresh machine may need `--with-deps` (or the equivalent
apt packages) — noted in the new README section rather than assumed.

### `config/cable.yml`: `test` environment adapter, `test` → `async`

```yaml
test:
  adapter: async
```

The `test` adapter (Rails' default scaffold choice) is an in-memory adapter built specifically
for `ActionCable::TestHelper`'s `assert_broadcast_on`/`assert_has_stream` — it doesn't deliver
messages over a real WebSocket connection at all, so a real browser subscribed via
`useImportProgress`/`useDashboardStats` would never receive anything during a system test.
`async` is a real, in-process pub/sub (no Redis/external process needed, same family as
`solid_cable` conceptually) that *does* deliver over real WebSocket connections.

Confirmed this doesn't break any existing channel/broadcaster test: reading
`actioncable-8.1.3.1/lib/action_cable/test_helper.rb`, `ActionCable::TestHelper#before_setup`
unconditionally replaces `ActionCable.server`'s pubsub with its own `SubscriptionAdapter::Test`
instance for the duration of any test that includes the helper — regardless of what `cable.yml`
configures. Every existing `assert_broadcast_on`/`assert_has_stream` test already runs against
that swapped-in adapter, not the configured one, so this change has no effect on them.

### Background jobs during system tests: `perform_enqueued_jobs`, not a real worker

Both places a system test needs a job to actually run — the spreadsheet import, and the password
reset email (`PasswordsMailer.reset(user).deliver_later`) — use Rails' own
`ActiveJob::TestHelper#perform_enqueued_jobs`, wrapping the browser action that triggers the
enqueue:

```ruby
perform_enqueued_jobs do
  attach_file "file", Rails.root.join("test/fixtures/files/imports/valid.csv")
  click_button "Upload"
end
```

This works even though the actual `perform_later` call happens inside the Puma server's request
thread, not the test's own thread: `perform_enqueued_jobs` just diffs the (process-global, not
thread-local) `ActiveJob::QueueAdapters::TestAdapter`'s `enqueued_jobs` array before/after the
block, and Capybara's `click_button` already blocks until that HTTP round trip (enqueue included)
has finished before returning.

The import fixture (`test/fixtures/files/imports/valid.csv`, already used by existing parser/job
tests — 2 rows, no `avatar_url` column) is reused deliberately: no `avatar_url` means
`SpreadsheetImportJob` never enqueues a nested `AttachRemoteAvatarJob`, which would otherwise
need its own handling inside (or after) the same `perform_enqueued_jobs` block.

**Rejected**: a real `SolidQueue::Worker` running in a background thread for the duration of the
import test (the user's first-offered, non-chosen option) — would let the test observe genuine
incremental progress (e.g. watching a percentage climb) instead of a single jump to "Completed",
at the cost of a worker thread to start/stop cleanly around the test and a slower, less
deterministic run. Rejected by the user in favor of the simpler option; the test still proves the
real job runs and a real broadcast reaches a real browser, just not paced.

### A separate `sign_in_as` for system tests

The existing `SessionTestHelper#sign_in_as` (`test/test_helpers/session_test_helper.rb`) works by
writing directly into Rails' internal integration-test cookie jar — that only exists because
`ActionDispatch::IntegrationTest` requests run in-process, sharing state with the test itself. A
Playwright-driven system test is a genuinely separate browser process with its own real cookie
jar, reachable only by an actual request/response cycle, so that trick doesn't apply here.

```ruby
# test/test_helpers/system_test_authentication_helper.rb
module SystemTestAuthenticationHelper
  def sign_in_as(user, password: "password")
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: password
    click_button "Sign in"
  end
end

ActiveSupport.on_load(:action_dispatch_system_test_case) do
  include SystemTestAuthenticationHelper
end
```

Costs a real page load + form submit per test that needs to start already authenticated (every
file except `sessions_test.rb` itself) — accepted as negligible at this app's scale (6 files, not
hundreds), and it's more honest than faking a session: it also incidentally re-verifies sign-in
keeps working on every run, rather than a storage-state shortcut that could silently drift from
what real sign-in actually requires.

### One file per page/flow, as requested

- `test/system/sessions_test.rb` — valid sign-in redirects by role (admin → `/admin/users`,
  everyone else → `/profile`), invalid credentials show an error, links to sign-up/forgot-password
  work.
- `test/system/registrations_test.rb` — a visitor can self-register (name/email/password only,
  see `feature/visitor-registration`) and lands on their own profile as a `default`-role User.
- `test/system/passwords_test.rb` — forgot/reset password as **one** file, not two: they're a
  single continuous journey (request → token → reset → sign in with the new password), and
  splitting the file would mean either duplicating the request step or awkwardly sharing state
  across files. Verifies the email is actually sent (`ActionMailer::Base.deliveries`) via
  `perform_enqueued_jobs`, then reaches the token through `user.password_reset_token` (the same
  method `has_secure_password`'s built-in `generates_token_for :password_reset` gives the mailer
  view) rather than regex-parsing the email body — the mailer's own rendering isn't what this
  test is checking.
- `test/system/admin/users_test.rb` — list, invite (create), edit, promote/demote role, delete,
  as one continuous admin session (matches how an admin would actually use the page in one
  sitting, and avoids re-signing-in per scenario).
- `test/system/admin/spreadsheet_imports_test.rb` — upload → progress modal reaches "Completed"
  live (a real WebSocket message, not a poll) → close it → the history row reflects the finished
  import with no page reload (see `chore/quality-hardening`'s "restrict the progress modal to
  fresh uploads" increment — this is exactly the flow that increment was built for).
- `test/system/profiles_test.rb` — a signed-in User can view/edit their own profile and delete
  their own account, ending back at the sign-in page.

## Post-Implementation Findings

Writing and stabilizing these tests surfaced several real things, one of them a genuine
production bug - not test-tooling noise to explain away, but findings worth recording plainly.

### A real bug: `flash[:notice]`/`flash[:alert]` never reached the frontend

`sessions_test.rb`'s invalid-credentials test kept failing to find `"Try another email address
or password."` on screen, even though the server log showed the request landing, matching, and
correctly redirecting with `alert:` set. Traced it to `InertiaController#inertia_share`:

```ruby
inertia_share do
  { current_user: Current.user&.as_json(only: %i[id email_address role]) }
end
```

Only `current_user` was ever shared. `inertia_rails` has its own, separate flash mechanism
(`flash.inertia[...]`, see `FlashExtension`) for exactly this use case, but nothing in this app
ever used it, and nothing bridges *plain* Rails `flash[:notice]`/`flash[:alert]` (what every
`redirect_to ..., notice:/alert:` call in this app actually uses - `sessions_controller.rb`,
`passwords_controller.rb`, `registrations_controller.rb`, `profiles_controller.rb`, 10 messages
in total) into Inertia's shared props at all. `sessions/new.tsx`, `passwords/new.tsx`, and
`passwords/edit.tsx` all read `usePage<{ flash?: FlashData }>().props.flash` - a prop that was
always `undefined`, so those `{flash?.alert && <p>...}` messages had never actually rendered,
for any user, ever. No existing controller test caught this because none of them asserted on the
*rendered* flash text - only on the redirect target and side effects (`assert_redirected_to`,
`assert_nil cookies[...]`), which is exactly what a real browser-driven test is for.

Brought to the user directly rather than silently patched or silently left broken (see chat) -
confirmed fixing it now, in this branch, made more sense than shipping E2E tests against a known-
broken flow. Fix:

```ruby
inertia_share do
  {
    current_user: Current.user&.as_json(only: %i[id email_address role]),
    flash: { notice: flash[:notice], alert: flash[:alert] }
  }
end
```

`bin/rails test test/controllers` stayed green after the change - confirming nothing was
accidentally depending on the old, broken behavior.

### A real, if narrow, UX finding: autofocus + blur-validation can shift layout mid-click

`sessions_test.rb`'s link-navigation test (`click_link "Sign up"`) intermittently landed on the
wrong element. Traced to: the sign-in page's email field is `autoFocus`ed and blur-validated
(`onBlur={() => touch('email_address')}`, see `useValidation`). Clicking anything else on the
page - a link, in this case - blurs that still-empty field, which synchronously inserts a new
`"can't be blank"` paragraph above the link, shifting it down between the click's `mousedown` and
`mouseup`. A synthetic click is fast enough to straddle that shift and land on whatever's now
underneath it; a real person's mouse-down-to-mouse-up gap is long enough that the shift has
already happened before they click. Confirmed by hand: `el.click()` (a JS-dispatched click,
immune to physical mid-click layout shifts) always lands correctly; a physical coordinate-based
click intermittently doesn't, only on pages with this exact pattern.

Not treated as an app bug worth fixing - real users are never fast enough to trigger it, and
"blur an empty required field shows its error" is the intended behavior everywhere else in this
app. Worked around at the test level only, in the one test that clicks a link before ever
touching that page's autofocused field: click a stable, non-field element (the `h1`) first, so
any shift this causes happens *before* the click that's actually being tested, not during it.

### A test-infrastructure finding: synthetic fill can race ahead of React's own re-render

Separately, filling a field via Capybara/Playwright and immediately clicking Submit could
intermittently produce *no* request at all - traced to this app's own `useValidation`-driven
`if (!isValid) { touchAll(); return }` guard reading a still-stale `data` snapshot: Playwright's
`fill`/`type` dispatch real DOM events and return as soon as the browser has processed them,
without waiting for React's own (asynchronous) state commit and re-render that follows. A real
person is never fast enough between typing and clicking to hit this window either.

Added `ApplicationSystemTestCase#settle_after_fill!` (a deliberate, documented, short pause)
called after the last `fill_in` and before the submit click in every form-driving test. Considered
polling on some observable signal instead of a flat pause; nothing reliable was available without
adding test-only instrumentation to the app itself, which felt like more machinery than this
warranted.

### `sign_in_as` needed to wait for its own redirect before returning

Building `spreadsheet_imports_test.rb` surfaced a related race: `sign_in_as`, followed
immediately by a fresh `visit`, occasionally landed back on the sign-in page - the helper
returned as soon as the submit *click* registered, not once the resulting session cookie was
actually set. A caller that follows `sign_in_as` with an assertion (which retries) absorbed this
by accident; a caller that follows it with a fresh `visit` (which doesn't retry) did not. Fixed
by having `sign_in_as` itself wait (`assert_no_selector "h1", text: "Sign in"`) before returning,
rather than relying on every caller to happen to do something that retries.

### `bin/rails test` doesn't include system tests - that's Rails' own default, not a gap here

`bin/rails -T test` says so directly: *"Run all tests in test folder except system ones."*
`bin/rails test:system` runs this suite; both are run and confirmed green in verification below.

### The password-mismatch test needed revising from the original plan

Task 5.3 was planned as "a mismatched confirmation shows an error" (implying the server's
`"Passwords did not match."` message). In practice, `passwordsEditSchema`'s `.refine` check
(added in `chore/quality-hardening`) catches this client-side and blocks the submit entirely -
correct, intended behavior, just not what the task description assumed. The test now asserts the
client message and that the page never navigates away from the form, rather than the server one.

## Risks / Trade-offs

- **[The import test never observes genuine incremental progress]** → Accepted trade-off from
  the `perform_enqueued_jobs` decision above; the real job and a real broadcast still run, just
  without pacing.
- **[Browser binary install needed `--with-deps` skipped in this sandbox]** → A fresh machine or
  CI may need it (or the equivalent apt packages) to launch Chromium at all; documented in the
  README rather than silently assumed to always work.
- **[No CI to actually run this suite automatically]** → Explicitly out of scope (no pipeline
  exists in this repo yet); these tests are runnable locally today, wiring them into CI is a
  separate, later effort.
- **[`sign_in_as` re-driving the real sign-in form adds real time to every file but
  `sessions_test.rb`]** → Accepted as negligible at 6 files; see the "separate `sign_in_as`"
  decision above for why a shortcut wasn't used instead.
- **[A fixed `sleep` in `settle_after_fill!` rather than a polled condition]** → No reliable
  observable signal existed without adding test-only instrumentation to the app; see
  "Post-Implementation Findings" above. If this ever becomes flaky under different load/CI
  conditions, revisit with an explicit wait condition instead of a longer sleep.

## Migration Plan

No schema/data migrations. `cable.yml`'s test-adapter change and the Gemfile swap
(`selenium-webdriver` → `capybara-playwright-driver`) are both easily reverted; the new test
files are purely additive. Rollback for any item is a plain revert.
