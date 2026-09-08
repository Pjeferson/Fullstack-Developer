## Why

Right now a signed-in User has no way to see or change their own account —
only an admin can edit a User, through `/admin/users`, and non-admins are
explicitly blocked from that area. Every User needs to be able to manage
their own basic info without asking an admin to do it for them, and land
somewhere useful (their own profile) after signing in instead of the
`inertia_example` demo page.

## What Changes

- New self-service profile page at `/profile`, scoped to the signed-in
  User's own record — no `:id` in the URL, no way to view or edit anyone
  else's account.
- A User can view their email, full name, role (read-only), and avatar.
- A User can edit their full name, email address, and avatar (upload or
  remote URL) — the same fields and the same avatar upload/URL/SSRF
  handling as the admin edit form, minus `role`, which stays admin-only
  (unchanged from admin-user-management).
- A User can delete their own account from this page. **BREAKING** (route
  behavior): this reuses none of `/admin/users/:id`'s DELETE route — a
  non-admin was already blocked from that route, so this doesn't reopen
  it; it adds a new, separate self-only deletion path.
- After signing in, a non-admin User is redirected to `/profile` instead
  of root; an admin is still redirected to `/admin/users` (root
  previously pointed both at the `inertia_example` demo page — there is
  no dashboard yet, that is a separate future change, so `/admin/users`
  is the closest existing "landing page" for an admin today).
- After a User deletes their own account, they are signed out (session
  destroyed, cookie cleared) and redirected to sign in with a
  confirmation message — the same effect as the existing sign-out flow.

## Capabilities

### New Capabilities
- `user-profile`: view/edit/delete one's own User account, avatar
  upload/URL handling reused from the admin capability's rules.

### Modified Capabilities
- `authentication`: the "Sign in with email and password" requirement's
  successful-sign-in redirect changes from "the page the User originally
  tried to reach (or root)" to "...(or `/profile` for a non-admin User,
  `/admin/users` for an admin)".

## Impact

- `config/routes.rb`: new `resource :profile` (singular, no `:id`).
- New `ProfilesController` (or similar), reusing `Users::AvatarAssigner`
  for the avatar field.
- `app/controllers/concerns/authentication.rb` / `SessionsController`:
  `after_authentication_url` needs to branch on the signed-in User's role
  instead of always falling back to `root_url`.
- New `app/javascript/pages/profiles/show.tsx` (or `edit.tsx` — TBD in
  design) page; likely reuses the existing `AvatarField` component as-is.
- No schema changes — reuses the `User` model and `Users::AvatarAssigner`
  exactly as they exist today.
