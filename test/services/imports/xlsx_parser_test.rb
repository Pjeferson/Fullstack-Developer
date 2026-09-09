require "test_helper"

module Imports
  class XlsxParserTest < ActiveSupport::TestCase
    FIXTURES = Rails.root.join("test/fixtures/files/imports")

    test "each_row yields a Hash per data row, same shape as CsvParser" do
      csv_rows = []
      CsvParser.new(FIXTURES.join("valid.csv")).each_row { |row| csv_rows << row }

      xlsx_rows = []
      XlsxParser.new(FIXTURES.join("valid.xlsx")).each_row { |row| xlsx_rows << row }

      assert_equal csv_rows, xlsx_rows
    end

    test "each_row without a block returns an Enumerator" do
      enum = XlsxParser.new(FIXTURES.join("valid.xlsx")).each_row

      assert_kind_of Enumerator, enum
      assert_equal 2, enum.to_a.size
    end

    test "each_row supports each_slice for batching" do
      batches = XlsxParser.new(FIXTURES.join("valid.xlsx")).each_row.each_slice(1).to_a

      assert_equal 2, batches.size
    end

    test "row_count counts data rows, excluding the header" do
      assert_equal 2, XlsxParser.new(FIXTURES.join("valid.xlsx")).row_count
      assert_equal 0, XlsxParser.new(FIXTURES.join("empty.xlsx")).row_count
    end

    test "each_row on a malformed file raises an error" do
      assert_raises(Zip::Error) do
        XlsxParser.new(FIXTURES.join("malformed.xlsx")).each_row { |row| row }
      end
    end
  end
end
