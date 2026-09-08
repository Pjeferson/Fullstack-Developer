# Selects the right Imports::Parser for an uploaded file. A selection, not an action, so it
# stays a class method (`.for`) rather than this project's usual `new(...).call` service shape.
module Imports
  class ParserFactory
    CONTENT_TYPES = {
      "text/csv" => CsvParser,
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => XlsxParser
    }.freeze

    EXTENSIONS = {
      ".csv" => CsvParser,
      ".xlsx" => XlsxParser
    }.freeze

    def self.for(content_type:, filename:, path:)
      parser_class = CONTENT_TYPES[content_type] || EXTENSIONS[File.extname(filename.to_s).downcase]
      raise UnsupportedFormatError, "unsupported file type: #{content_type} (#{filename})" unless parser_class

      parser_class.new(path)
    end
  end
end
