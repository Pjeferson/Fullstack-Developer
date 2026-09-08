## 1. Routing & controller

- [x] 1.1 Add `resource :profile, only: %i[show update destroy]` to `config/routes.rb` and verify `bin/rails routes | grep profile` shows `profile` (GET/PATCH/PUT/DELETE), no `:id` segment
- [x] 1.2 Add `ProfilesController < InertiaController` with `show`/`update`/`destroy`, always operating on `Current.user` (no `id`/`user_id` param read anywhere in the controller) — verify with a request test asserting there is no route parameter that can target another User
- [x] 1.3 Add `profile_params`/`avatar_params` private methods mirroring `Admin::UsersController` (`email_address`, `full_name`; `avatar_image`, `avatar_image_url`) with `role` never permitted — verify with a test asserting a submitted `role` value has no effect on `Current.user.role`
- [x] 1.4 Call `Users::AvatarAssigner` from `update`, after `Current.user.update(profile_params)` succeeds, same ordering/error-surfacing pattern as `Admin::UsersController#update` — verify with tests covering a valid upload, a valid URL (job enqueued), and a rejected upload (bad type/size) each surfacing errors via `inertia: { errors: ... }`

## 2. Post-login redirect

- [ ] 2.1 Change `after_authentication_url` in `app/controllers/concerns/authentication.rb` to fall back on `Current.user.admin? ? admin_users_url : profile_url` instead of `root_url` — verify with `SessionsControllerTest` cases for both an admin and a non-admin signing in with no prior `return_to_after_authenticating`
- [ ] 2.2 Verify the existing "return to originally requested page" behavior (`return_to_after_authenticating`) still takes precedence over the role-based fallback — add a regression test if the existing suite doesn't already cover a protected-page-first-then-sign-in flow

## 3. Self-delete session handling

- [ ] 3.1 Implement `ProfilesController#destroy` to call the existing `terminate_session` helper before destroying `Current.user`, then redirect to `new_session_path` with a confirmation notice — verify with a test asserting the Session row and cookie are gone and the response redirects to sign-in
- [ ] 3.2 Verify `Current.user`'s avatar attachment and sessions are cleaned up on delete (already covered by `dependent: :destroy`/`dependent: :purge_later` on the model — confirm with a test, don't re-implement)

## 4. Frontend

- [ ] 4.1 Add `app/javascript/pages/profiles/show.tsx`: a single page showing the current values (email, full name, role read-only) as a pre-filled editable form, reusing the existing `AvatarField` component as-is — verify `npm run check` passes
- [ ] 4.2 Wire the delete action with the same `router.delete(path, { onBefore: () => confirm(...) })` pattern already used on `admin/users/index.tsx` — verify manually that cancelling the confirm dialog aborts the request
- [ ] 4.3 Confirm there is no nav link to `/profile` needed for an admin beyond what already exists (admins reach `/admin/users`); add a "My profile" link somewhere reachable for a non-admin, since `AdminLayout` doesn't apply to them — decide the minimal placement (e.g. a small top-of-page identity line, no new shared layout needed for one page) and verify it renders

## 5. Full verification

- [ ] 5.1 Run `bin/rails test` — full suite green
- [ ] 5.2 Run `bin/rubocop` and `bin/brakeman` on touched files — clean
- [ ] 5.3 Run `npm run check` — clean
- [ ] 5.4 Manual smoke test (via the `run` skill or curl, per the pattern used for admin-user-management): sign in as a non-admin, land on `/profile`, edit info, upload/URL an avatar, delete the account, confirm redirected to sign-in and signed out; sign in as an admin, confirm still landing on `/admin/users`
