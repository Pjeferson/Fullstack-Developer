# Creates a couple of known-password accounts so a freshly set-up environment has something to
# sign in with immediately, rather than only being reachable via self-registration (which always
# creates a `default`-role User - there'd be no way to see the admin side of the app at all
# without this). Idempotent: safe to run again against an already-seeded database.

admin = User.find_or_create_by!(email_address: "admin@example.com") do |user|
  user.full_name = "Admin User"
  user.password = "password"
  user.role = :admin
end

User.find_or_create_by!(email_address: "user@example.com") do |user|
  user.full_name = "Sample User"
  user.password = "password"
end

puts "Seeded #{User.count} user(s). Sign in as admin: #{admin.email_address} / password"
