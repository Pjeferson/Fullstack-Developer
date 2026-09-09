## Context

See proposal.md for motivation. Relevant existing state:

- **`Authentication` concern** (`app/controllers/concerns/authentication.rb`) already has
  everything registration needs as private instance methods, inherited via
  `ApplicationController` → `InertiaController`: `start_new_session_for(user)` (creates the
  Session, sets the signed cookie), `after_authentication_url` (`Current.user.admin? ?
  admin_users_url : profile_url`, falling back to a remembered return-to URL), and `authenticated?`
  (calls `resume_session`, which populates `Current.session`/`Current.user` from the cookie even
  when the `require_authentication` before_action has been skipped via `allow_unauthenticated_access`).
- **`User` already validates everything registration needs**: `email_address`
  (presence/uniqueness/format), `full_name` (presence), and `has_secure_password` adds password
  presence — no model change required. `has_secure_password`'s `password_confirmation` check only
  runs when that param is present at all; the registration form never sends it, so it's simply
  never checked.
- **`SessionsController#create`** is the existing precedent for "authenticate, start a session,
  redirect via `after_authentication_url`" — `RegistrationsController#create` follows the exact
  same shape, substituting `User.new(...).save` for `User.authenticate_by(...)`.
- **`root` currently points at `InertiaExampleController#index`**, a Rails/Inertia scaffold demo
  page never adapted for this app (confirmed: nothing outside `config/routes.rb` and its own
  `app/javascript/pages/inertia_example/` directory references it — no test file exists for it
  either).
- **The three existing auth pages** (`pages/sessions/new.tsx`, `pages/passwords/{new,edit}.tsx`)
  predate the `design-system` branch and were never migrated — plain `gray-*` classes,
  hand-rolled `<input>`s, each with its own copy of the same `mx-auto w-full max-w-sm` centering
  wrapper (itself a stopgap added when `design-system` removed the old global `<main>` wrapper
  that used to supply it — see that branch's design.md).
- **`ui/Input`'s `error` prop is `string[]`**, matching how Rails serializes `record.errors` and
  how every other form in the app (`UserForm`, `profiles/show.tsx`) already renders it — see
  `types/globals.d.ts`'s `InertiaConfig` override.

## Goals / Non-Goals

**Goals:**
- A Visitor can create a `default`-role account with just full name, email, and password, and is
  signed in and correctly redirected immediately.
- Every unauthenticated entry point (`/`, `/session/new`) leads to sign-in; every authenticated
  visit to either bounces to the User's actual landing page instead of re-showing the form.
- The four auth pages (sign-in, forgot-password, reset-password, register) share one visual
  system and one layout component.
- The leftover example scaffold is gone; `root` no longer depends on it.

**Non-Goals:**
- A password-confirmation field or an avatar field on registration — deliberately kept to the
  three fields named in scope.
- Any change to how `PasswordsController` or `ProfilesController` behave — only presentation.
- Rate-limit or other behavioral tests beyond what already exists for `SessionsController`/
  `PasswordsController` (neither has a rate-limit test today; registration's `rate_limit` call
  stays consistent with that existing depth of coverage, not a new bar for this one action).

## Decisions

### `RegistrationsController` mirrors `SessionsController`'s shape exactly

```ruby
class RegistrationsController < InertiaController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Try again later." }

  def new
    redirect_to(after_authentication_url) and return if authenticated?
    render inertia: {}
  end

  def create
    user = User.new(registration_params)
    if user.save
      start_new_session_for(user)
      ::Dashboard::StatsBroadcaster.new.call
      redirect_to after_authentication_url
    else
      redirect_to new_registration_path, inertia: { errors: user.errors }
    end
  end

  private
    # role is structurally absent - the same "not even permitted" guarantee
    # Admin::UsersController/ProfilesController already give `role` elsewhere. A registered User
    # is `default` by the enum's own default, not by a check here.
    def registration_params
      params.permit(:full_name, :email_address, :password)
    end
end
```

Rejected: a `Users::Registrar` service object, mirroring `Users::Inviter`. `Users::Inviter`
exists specifically to keep "always sends an email" out of `User` — registration has no such
side effect to isolate (no email is sent; the Visitor sets their own password directly), so a
service here would wrap `User.new(...).save` with nothing to justify the indirection. Plain
`ActiveRecord` in the controller, same as `ProfilesController#update` already does for a
comparable single-record write.

`Dashboard::StatsBroadcaster.new.call` on success closes a real gap: every other User-count-
changing path already broadcasts (admin invite, admin delete, self-service delete, role toggle,
each spreadsheet-import batch — see `dashboard-realtime`'s design.md's explicit list), and
registration was the one missing from it, not a new pattern being introduced.

### `root "sessions#new"`, not a redirect route

```ruby
root "sessions#new"
```
Rejected: `root to: redirect("/session/new")`. A redirect route can't run controller logic (the
authenticated-visitor guard below), so an authenticated User hitting `/` would still round-trip
through a redirect to `/session/new` and then need the *same* guard there anyway — pointing
`root` directly at the action `new_session_path` already resolves to avoids the extra hop and the
duplicate logic. `/` and `/session/new` end up as two URLs for the same page, which is fine:
`new_session_path` remains the canonical link every other page uses.

### Authenticated-visitor guard on `#new`, not a route-level constraint

```ruby
def new
  redirect_to(after_authentication_url) and return if authenticated?
  render inertia: {}
end
```
Added identically to both `SessionsController#new` and `RegistrationsController#new`. `authenticated?`
already exists on the `Authentication` concern and already resumes the session from the cookie
even when `require_authentication` itself is skipped (which it is here, via
`allow_unauthenticated_access`) — calling it explicitly at the top of `#new` is the whole change;
no new concern method needed. Rejected: gating this at the route/middleware level — it needs
`Current.user`, which only exists once a controller has resumed the session, so it has to live in
the controller action either way; doing it inline keeps it next to the one line of behavior it
adds, rather than a separate constraint object for two call sites.

### Shared `AuthLayout`, not per-page wrappers

```tsx
export default function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background px-4 py-12">
      <Link href="/" className="mb-6 flex items-center gap-2">
        <LayoutDashboard className="h-6 w-6 text-primary" />
        <span className="text-lg font-semibold tracking-tight text-text">Umanni</span>
      </Link>
      <Card className="w-full max-w-sm">{children}</Card>
    </div>
  )
}
```
Same brand mark `Sidebar` already uses (`LayoutDashboard` icon + "Umanni"), so the app reads as
one product whether a visitor is looking at the sign-in page or the authenticated admin shell.
Used by all four auth pages via `.layout`, the same mechanism `AppShell` already established for
authenticated pages — replacing each page's own `mx-auto w-full max-w-sm` div. Every field moves
onto `ui/Input`/`ui/Button`, and each page imports the existing `FlashData` type from `@/types`
instead of redeclaring its own inline flash-prop type (a small pre-existing inconsistency, fixed
in passing since these files are already being rewritten).

## Risks / Trade-offs

- **[`root` and `/session/new` are now two URLs for the same page]** → Acceptable and standard
  (many apps do exactly this for their sign-in page); `new_session_path` stays the one canonical
  link every other page/redirect uses, `root` is just an alias for convenience.
- **[No password-confirmation field on registration, unlike the password-reset page]** →
  Deliberate, per the confirmed scope (full name, email, password only) — a visible asymmetry
  with `passwords/edit.tsx`, but the reset flow's confirmation field exists because a mistyped
  new password there is unrecoverable without another reset round-trip; a mistyped registration
  password is trivially fixed via "forgot password" right after signing up.
- **[No new service object for registration, unlike `Users::Inviter`]** → Deliberate, see
  Decisions above — there's no side effect (email, background job) to isolate from `User` here.
