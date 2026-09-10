# Cursor-based (not offset-based) pagination for the admin User list — newest first, 25 at a
# time. A WHERE id < :before_id cursor stays correct even while Users are being created (e.g.
# a spreadsheet import running concurrently), unlike offset pagination, which would shift or
# duplicate rows across pages as new Users are inserted at the top. See design.md under
# openspec/changes/dashboard-realtime.
module Admin
  class UsersQuery
    PER_PAGE = 25

    # `scope:` lets the caller decide what to eager-load (e.g. User.with_attached_avatar_image)
    # instead of this query object hardcoding one specific attachment — see design.md under
    # openspec/changes/quality-hardening.
    def initialize(before_id: nil, scope: User.all)
      @before_id = before_id
      @scope = scope
    end

    def records
      fetched.first(PER_PAGE)
    end

    def metadata
      {
        page_name: "before_id",
        current_page: before_id,
        previous_page: nil, # this list only ever loads forward — see design.md
        next_page: has_more? ? records.last&.id : nil
      }
    end

    private
      attr_reader :before_id, :scope

      # Fetching PER_PAGE + 1 rows and slicing is how #has_more? knows whether another page
      # exists without a separate COUNT(*) query.
      def fetched
        @fetched ||= begin
          relation = scope.order(id: :desc).limit(PER_PAGE + 1)
          relation = relation.where(User.arel_table[:id].lt(before_id)) if before_id
          relation.to_a
        end
      end

      def has_more? = fetched.size > PER_PAGE
  end
end
