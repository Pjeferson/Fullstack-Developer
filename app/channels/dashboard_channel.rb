# Streams the admin dashboard's live stats (total Users, Users by role) — a single global
# stream, not scoped to any one record, so every subscribed admin watches the same broadcast.
class DashboardChannel < ApplicationCable::Channel
  def subscribed
    reject and return unless current_user&.admin?

    stream_from "dashboard_stats"
  end
end
