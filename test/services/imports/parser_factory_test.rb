require "test_helper"

module Imports
  class ParserFactoryTest < ActiveSupport::TestCase
    FIXTURES = Rails.root.join("test/fixtures/files/imports")

    test "selects CsvParser by content type" do
      parser = ParserFactory.for(content_type: "text/csv", filename: "valid.csv", path: FIXTURES.join("valid.csv"))

      assert_kind_of CsvParser, parser
    end

    test "selects XlsxParser by content type" do
      parser = ParserFactory.for(
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        filename: "valid.xlsx",
        path: FIXTURES.join("valid.xlsx")
      )

      assert_kind_of XlsxParser, parser
    end

    test "falls back to the filename extension when the content type is generic" do
      parser = ParserFactory.for(content_type: "text/plain", filename: "valid.csv", path: FIXTURES.join("valid.csv"))

      assert_kind_of CsvParser, parser
    end

    test "raises UnsupportedFormatError for an unrecognized type and extension" do
      assert_raises(UnsupportedFormatError) do
        ParserFactory.for(content_type: "application/pdf", filename: "report.pdf", path: "/tmp/report.pdf")
      end
    end
  end
end
