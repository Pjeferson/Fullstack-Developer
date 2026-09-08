# Shared contract for reading rows out of an uploaded spreadsheet, regardless of its
# format — the import job only ever talks to this interface, never to CSV/roo directly.
module Imports
  module Parser
    # Yields a Hash per data row (header => cell value), skipping the header row itself.
    # Returns an Enumerator when called without a block, so callers can chain
    # Enumerable methods like `each_slice` on it.
    def each_row
      raise NotImplementedError
    end

    # Total number of data rows (excluding the header row).
    def row_count
      raise NotImplementedError
    end
  end
end
