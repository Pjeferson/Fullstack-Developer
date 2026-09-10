# Cursor-based (not offset-based) pagination for the admin import history — newest first, 25 at
# a time. Same shape as Admin::UsersQuery (WHERE id < :before_id, fetch PER_PAGE + 1 to detect a
# next page without a separate COUNT(*)) - no reason to invent a second pagination strategy for
# a second admin list. See design.md under openspec/changes/design-system.
module Admin
  class SpreadsheetImportsQuery
    PER_PAGE = 25

    # `scope:` lets the caller decide what to eager-load (e.g. SpreadsheetImport.with_attached_file,
    # to avoid an N+1 on each import's filename) instead of this query object hardcoding it — see
    # design.md under openspec/changes/quality-hardening.
    def initialize(before_id: nil, scope: SpreadsheetImport.all)
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

      def fetched
        @fetched ||= begin
          relation = scope.order(id: :desc).limit(PER_PAGE + 1)
          relation = relation.where(SpreadsheetImport.arel_table[:id].lt(before_id)) if before_id
          relation.to_a
        end
      end

      def has_more? = fetched.size > PER_PAGE
  end
end
