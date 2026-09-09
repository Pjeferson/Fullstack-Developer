require "test_helper"

module Admin
  class SpreadsheetImportsQueryTest < ActiveSupport::TestCase
    setup do
      SpreadsheetImport.delete_all
      # 30 imports, ids ascending with creation order — @imports.last is newest.
      @imports = 30.times.map { SpreadsheetImport.create!(admin: users(:admin)) }
    end

    test "the first page returns the 25 newest imports" do
      records = SpreadsheetImportsQuery.new.records

      assert_equal @imports.last(25).reverse.map(&:id), records.map(&:id)
    end

    test "next_page is the 26th import's id when more imports exist" do
      query = SpreadsheetImportsQuery.new
      query.records

      assert_equal @imports[5].id, query.metadata[:next_page]
    end

    test "next_page is nil when exhausted" do
      query = SpreadsheetImportsQuery.new(before_id: @imports[4].id)
      query.records

      assert_nil query.metadata[:next_page]
    end

    test "passing before_id returns the next 25 older than that id" do
      records = SpreadsheetImportsQuery.new(before_id: @imports[5].id).records

      assert_equal @imports.first(5).reverse.map(&:id), records.map(&:id)
    end

    test "an import created after an earlier page was fetched doesn't appear again or shift a later page" do
      first_page = SpreadsheetImportsQuery.new.records
      before_id = first_page.last.id

      SpreadsheetImport.create!(admin: users(:admin))

      second_page = SpreadsheetImportsQuery.new(before_id: before_id).records

      assert_equal @imports.first(5).reverse.map(&:id), second_page.map(&:id)
    end
  end
end
