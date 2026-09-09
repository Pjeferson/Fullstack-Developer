## 1. Remove the example scaffold

- [x] 1.1 Delete `app/controllers/inertia_example_controller.rb` and
  `app/javascript/pages/inertia_example/` (`index.tsx`, `index.module.css`)
- [x] 1.2 Remove `get 'inertia-example', ...` and the old `root 'inertia_example#index'` from
  `config/routes.rb`

## 2. Registration backend

- [x] 2.1 Add `app/controllers/registrations_controller.rb` (`allow_unauthenticated_access`,
  `rate_limit` on `#create` matching `SessionsController`'s; `#new` redirects an already-
  authenticated visitor via `after_authentication_url`; `#create` builds `User.new(registration_params)`,
  and on success calls `start_new_session_for` + `Dashboard::StatsBroadcaster.new.call` before
  redirecting via `after_authentication_url`, or redirects back to `new_registration_path` with
  `inertia: { errors: }` on failure; `registration_params` permits only `:full_name,
  :email_address, :password` — `role` structurally absent)
- [x] 2.2 Add the same authenticated-visitor guard to `SessionsController#new`
- [x] 2.3 `config/routes.rb`: add `resource :registration, only: %i[new create]`, change `root`
  to `"sessions#new"`
- [x] 2.4 Add `test/controllers/registrations_controller_test.rb`: guest can view `new`; an
  authenticated User visiting `new` is redirected to `after_authentication_url`; valid signup
  creates a `default`-role User, signs them in (cookie set), redirects to `/profile`; a `role`
  param submitted alongside is ignored (structural-absence regression test, mirroring
  `admin/users_controller_test.rb`'s); duplicate/blank email, blank full name, and blank password
  each redirect back with errors and create no User; successful registration broadcasts
  `dashboard_stats` (`assert_broadcast_on`, mirroring `admin/users_controller_test.rb`'s existing
  cases), a failed one does not
- [x] 2.5 Add a case to `test/controllers/sessions_controller_test.rb` for the new
  authenticated-redirect guard on `#new`
- [x] 2.6 Run `bin/rails test` — full suite green

## 3. Frontend: shared AuthLayout and rebuilt auth pages

- [ ] 3.1 Add `components/layout/AuthLayout.tsx` (brand header matching `Sidebar`'s + centered
  `ui/Card`)
- [ ] 3.2 Rewrite `pages/sessions/new.tsx` onto `ui/Input`/`ui/Button`, import `FlashData` from
  `@/types` instead of an inline type, add a "Don't have an account? Sign up" link to
  `/registration/new`, `.layout = AuthLayout`
- [ ] 3.3 Rewrite `pages/passwords/new.tsx` and `pages/passwords/edit.tsx` the same way (fields
  only — no behavior change), `.layout = AuthLayout`
- [ ] 3.4 Add `pages/registrations/new.tsx` (full name, email, password — no confirmation field,
  no avatar picker), "Already have an account? Sign in" link to `/session/new`,
  `.layout = AuthLayout`
- [ ] 3.5 Run `bin/rails test` and `npm run check` — both clean

## 4. Final verification

- [ ] 4.1 Run `bin/rubocop` and `bin/brakeman` — no new offenses
- [ ] 4.2 Manual smoke test via a real browser: visit `/` signed out → redesigned sign-in page;
  follow "Sign up" → register a new User → confirm redirect to `/profile` and that the new User
  shows up as a `default`/Member in the admin dashboard's live count; sign out, sign back in as
  the admin fixture → redirected to `/admin/users`; visit `/` again while already signed in
  (either account) → bounced straight to the landing page instead of seeing the form; resize the
  auth pages to mobile to confirm `AuthLayout` holds up at narrow widths
