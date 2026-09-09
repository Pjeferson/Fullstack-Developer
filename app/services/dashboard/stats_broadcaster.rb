# Pushes the current dashboard stats to every subscribed admin. Called explicitly from each
# controller/job action that actually changes a User count or role — deliberately not an
# ActiveRecord callback, same reasoning as Imports::ProgressBroadcaster (see design.md under
# openspec/changes/dashboard-realtime).
module Dashboard
  class StatsBroadcaster
    def call
      ActionCable.server.broadcast("dashboard_stats", Dashboard::StatsQuery.new.call)
    end
  end
end
