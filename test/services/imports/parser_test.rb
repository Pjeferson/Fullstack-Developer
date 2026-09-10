require "test_helper"

module Imports
  class ParserTest < ActiveSupport::TestCase
    # A minimal include - not a stand-in for CsvParser/XlsxParser - just enough to exercise the
    # contract's own default bodies, which every real parser overrides.
    class IncompleteParser
      include Imports::Parser
    end

    test "each_row raises NotImplementedError when not overridden" do
      assert_raises(NotImplementedError) { IncompleteParser.new.each_row }
    end

    test "row_count raises NotImplementedError when not overridden" do
      assert_raises(NotImplementedError) { IncompleteParser.new.row_count }
    end
  end
end
