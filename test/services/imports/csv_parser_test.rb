require "test_helper"

module Imports
  class CsvParserTest < ActiveSupport::TestCase
    FIXTURES = Rails.root.join("test/fixtures/files/imports")

    test "each_row yields a Hash per data row" do
      rows = []
      CsvParser.new(FIXTURES.join("valid.csv")).each_row { |row| rows << row }

      assert_equal [
        { "email_address" => "alice@example.com", "full_name" => "Alice Alison", "role" => nil },
        { "email_address" => "bob@example.com", "full_name" => "Bob Bobson", "role" => "admin" }
      ], rows
    end

    test "each_row without a block returns an Enumerator" do
      enum = CsvParser.new(FIXTURES.join("valid.csv")).each_row

      assert_kind_of Enumerator, enum
      assert_equal 2, enum.to_a.size
    end

    test "each_row supports each_slice for batching" do
      batches = CsvParser.new(FIXTURES.join("valid.csv")).each_row.each_slice(1).to_a

      assert_equal 2, batches.size
    end

    test "row_count counts data rows, excluding the header" do
      assert_equal 2, CsvParser.new(FIXTURES.join("valid.csv")).row_count
      assert_equal 0, CsvParser.new(FIXTURES.join("empty.csv")).row_count
    end

    test "each_row on a malformed file raises a CSV error" do
      assert_raises(CSV::MalformedCSVError) do
        CsvParser.new(FIXTURES.join("malformed.csv")).each_row { |row| row }
      end
    end
  end
end
