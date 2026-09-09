# Computes the current User totals shown on the admin dashboard. by_role is built from
# User.roles.keys (not User.group(:role).count directly) so a role with zero Users still
# appears as 0 rather than being silently omitted — see design.md under
# openspec/changes/dashboard-realtime.
module Dashboard
  class StatsQuery
    def call
      { total: User.count, by_role: User.roles.keys.index_with { |role| User.where(role: role).count } }
    end
  end
end
