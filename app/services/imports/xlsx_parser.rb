module Imports
  class XlsxParser
    include Parser

    def initialize(path)
      @path = path
    end

    def each_row
      return enum_for(:each_row) unless block_given?

      headers = nil
      sheet.each_row_streaming(pad_cells: true) do |cells|
        values = cells.map { |cell| cell&.value }
        if headers.nil?
          headers = values.map(&:to_s)
          next
        end
        yield headers.zip(values).to_h
      end
    end

    def row_count
      sheet.each_row_streaming.count - 1 # exclude the header row
    end

    private
      attr_reader :path

      def sheet
        Roo::Spreadsheet.open(path, extension: :xlsx)
      end
  end
end
