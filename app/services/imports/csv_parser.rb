module Imports
  class CsvParser
    include Parser

    def initialize(path)
      @path = path
    end

    def each_row
      return enum_for(:each_row) unless block_given?

      CSV.foreach(path, headers: true) { |row| yield row.to_h }
    end

    def row_count
      CSV.foreach(path, headers: true).count
    end

    private
      attr_reader :path
  end
end
