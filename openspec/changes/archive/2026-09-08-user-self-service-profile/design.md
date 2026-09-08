## Context
See proposal.md - Why. Relevant existing pieces this builds on: the
`Authentication` concern (`Current.session`/`Current.user`,
`terminate_session`, `after_authentication_url`), `Users::AvatarAssigner`
(already generic — takes a `User` + `file:`/`url:`, no admin-specific
assumptions), and `Admin::UsersController`'s edit form as the closest
existing reference for field layout/validation-error handling.

## Goals / Non-Goals

**Goals:**
- A signed-in User can view, edit, and delete only their own account.
- Reuse `Users::AvatarAssigner` and the existing avatar UI pattern as-is.
- Role-aware post-login redirect, without a dashboard existing yet.

**Non-Goals:**
- Changing one's own password from this page (stays on the existing
  password-reset flow).
- The admin Dashboard (`/admin` landing page with live counters) — a
  separate future change; `/admin/users` remains the admin's landing
  page until then.
- Visitor self-registration — a separate future change.

## Decisions

**Route shape: `resource :profile, only: %i[show update destroy]`, no
`:id`.** A signed-in User only ever has one profile — their own — so
this is a singular resource, same pattern as `resource :session`. `show`
is the combined view+edit page (pre-filled form, same as
`Admin::UsersController#edit` already does — displaying current values
*is* the "view", a separate read-only page would just duplicate it).
`new`/`create` are excluded: accounts aren't created here (invite flow
for now; visitor self-registration is a separate future change). This
gives a clean `profile_path` (`/profile`) for the post-login redirect,
rather than `/profile/edit`.

**Controller always operates on `Current.user`, never on a param.**
`ProfilesController` (top-level, not under `Admin::`) reads
`Current.user` for every action — there is no `:id` in the route and no
`user_id`/`id` param read anywhere in the controller. This is the same
"make it structurally impossible" approach already used for keeping
`role` out of `Admin::UsersController`'s params: the safety property
here isn't "we remembered to scope the query," it's "there is no
parameter that could name a different User."

**Reuse `Users::AvatarAssigner` unchanged.** It already takes a `User`
instance plus `file:`/`url:` — nothing about it assumes an admin caller.
`ProfilesController` calls it exactly like `Admin::UsersController` does,
after `Current.user.update(profile_params)` succeeds (same ordering
requirement as the admin controller, for the same reason: validation
errors are cleared at the start of `update`'s own run).

**Strong params exclude `role`**, same reasoning and same shape as
`Admin::UsersController#user_params` — `params.permit(:email_address,
:full_name)` plus a separate `avatar_params` for
`:avatar_image`/`:avatar_image_url`. There is no path — admin or
self-service — where a User can set their own `role`.

**Self-delete terminates the session directly, not via cascade.**
`User#destroy` cascades to `has_many :sessions, dependent: :destroy`,
which would destroy the row backing the current cookie — but that alone
just makes the *next* request fail auth and bounce to sign-in; it
doesn't clear the cookie or redirect there directly. `ProfilesController
#destroy` calls the existing `terminate_session` (destroys
`Current.session`, clears the cookie) before destroying the User record,
then redirects straight to sign-in with a confirmation notice — matching
the "session ended + redirect to login" behavior confirmed for this
change, and avoiding the extra bounce-through admin self-delete
currently has (out of scope to fix there in this change; noted as a
side observation, not a task here).

**`after_authentication_url` becomes role-aware.** Currently:
```ruby
def after_authentication_url
  session.delete(:return_to_after_authenticating) || root_url
end
```
Changes to fall back on `Current.user.admin? ? admin_users_url :
profile_url` instead of always `root_url`. This lives in the
`Authentication` concern (shared by every controller), and `Current.user`
is already populated by this point in the sign-in flow
(`start_new_session_for` runs first). `root_url`/`inertia_example` is
untouched — it stops being anyone's post-login landing page, but nothing
else currently routes there either.

## Risks / Trade-offs

- [An admin visiting `/profile` directly (not just via post-login
  redirect) would see and edit their own account like any User] →
  Acceptable and arguably correct: an admin's own account is still just
  a User account; they should be able to self-service it too, the same
  as any other User. `/admin/users` stays the *admin-only* area; `/profile`
  is *everyone's* own-account area, admins included.
- [Reusing the exact admin avatar-handling code path means any future
  change to `Users::AvatarAssigner`'s validation affects both admin and
  self-service uploads] → Intentional, not a risk: the two capabilities
  describe the same underlying rule ("what's a valid avatar"), and
  keeping one implementation is exactly what avoids the two specs
  silently drifting apart.

## Migration Plan
No data migration. Purely additive route/controller/page plus one
behavior change to an existing method (`after_authentication_url`).
Rollback is a plain revert — no schema or irreversible state involved.
