## Why

This is the last of the three roadmap branches forking off `feature/authentication`'s User model
(`feature/users-admin-crud` and `feature/user-profile` already shipped) and closes the last open
use-case category from the challenge brief: a Visitor can register themselves as a `default`
User. It also rounds out the app's entry points so every audience lands in the right place: an
unauthenticated visitor at the root goes straight to sign-in (not the leftover `inertia_example`
demo page root currently points at), sign-in links to registration and back, and after either
signing in or registering, an admin lands on `/admin/users` while everyone else lands on
`/profile` — already true for sign-in, now true for registration too.

Separately, the three existing auth pages (sign-in, forgot-password, reset-password) never got
the design-system treatment from the previous branch — they still use raw `gray-*` Tailwind and
hand-rolled inputs with no shared layout. This change brings them in line alongside the new
registration page.

## What Changes

- Adds self-service registration: `RegistrationsController#new`/`#create`, route
  `resource :registration, only: %i[new create]`. A Visitor submits full name, email, and
  password only — no confirmation field, no avatar. `role` is structurally absent from the
  permitted params (same "not even permitted" guarantee `Admin::UsersController`/
  `ProfilesController` already give `role`), so a registered User is `default` by the enum's own
  default, not by a runtime check. On success, the Visitor is signed in immediately (reusing
  `Authentication#start_new_session_for`, exactly as `SessionsController#create` already does)
  and redirected via the existing `after_authentication_url` — for a brand-new `default` User,
  that's always `/profile`.
- Closes a real gap: registration broadcasts `dashboard_stats` on success, the one User-count-
  changing path that didn't already do this (invite, delete, role toggle, and import batches all
  already do, per `dashboard-realtime`).
- **BREAKING** (internal route only): `root` changes from `inertia_example#index` to
  `sessions#new` — `/` and `/session/new` become the same page. `SessionsController#new` (and the
  new `RegistrationsController#new`) gain a guard: an already-authenticated visitor hitting either
  is redirected to `after_authentication_url` instead of seeing the form again.
- Removes the example scaffold entirely: `InertiaExampleController`, its route, and
  `app/javascript/pages/inertia_example/*` — nothing in the graded app uses them.
- Adds a shared `components/layout/AuthLayout.tsx` (brand header + centered card, matching
  `AppShell`'s branding) used by all four auth pages via `.layout`, replacing each page's
  copy-pasted centering wrapper. Each page is rewritten onto `ui/Input`/`ui/Button`. Sign-in and
  the new registration page cross-link to each other.

Out of scope: any change to `PasswordsController`/`ProfilesController` behavior (only the auth
pages' presentation changes, not their logic), a password-confirmation field on registration, and
an avatar field on registration (added later via the profile page, same as any other User).

## Capabilities

### New Capabilities
- `visitor-registration`: lets a Visitor create their own `default`-role User account and be
  signed in immediately, and covers the root path's session-aware redirect behavior.

### Modified Capabilities
- None — `authentication`'s existing "Sign in" requirement already documents the role-based
  post-auth redirect that registration now also uses; no requirement text there changes.

## Impact

- **Backend**: new `app/controllers/registrations_controller.rb`; `app/controllers/
  sessions_controller.rb` (`#new` guard); `config/routes.rb` (`resource :registration`, `root`
  change, removed `inertia-example` route); deleted `app/controllers/
  inertia_example_controller.rb`.
- **Frontend**: new `components/layout/AuthLayout.tsx`, `pages/registrations/new.tsx`; rewritten
  `pages/sessions/new.tsx`, `pages/passwords/{new,edit}.tsx`; deleted
  `pages/inertia_example/*`.
- **Tests**: new `test/controllers/registrations_controller_test.rb`; `test/controllers/
  sessions_controller_test.rb` gains the authenticated-redirect-on-`#new` case. No other existing
  test file changes.
