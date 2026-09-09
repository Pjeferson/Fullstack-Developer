# Cursor-based (not offset-based) pagination for the admin import history — newest first, 25 at
# a time. Same shape as Admin::UsersQuery (WHERE id < :before_id, fetch PER_PAGE + 1 to detect a
# next page without a separate COUNT(*)) - no reason to invent a second pagination strategy for
# a second admin list. .with_attached_file avoids an N+1 on each import's filename, the same
# class of bug already flagged for avatars in the admin User list. See design.md under
# openspec/changes/design-system.
module Admin
  class SpreadsheetImportsQuery
    PER_PAGE = 25

    def initialize(before_id: nil)
      @before_id = before_id
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
      attr_reader :before_id

      def fetched
        @fetched ||= begin
          scope = SpreadsheetImport.with_attached_file.order(id: :desc).limit(PER_PAGE + 1)
          scope = scope.where(SpreadsheetImport.arel_table[:id].lt(before_id)) if before_id
          scope.to_a
        end
      end

      def has_more? = fetched.size > PER_PAGE
  end
end
