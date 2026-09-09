# Pushes a SpreadsheetImport's current state to its channel. Called explicitly by
# SpreadsheetImportJob right after each update — deliberately not an ActiveRecord callback, so
# persistence and the side effect of broadcasting stay visibly separate (see design.md under
# openspec/changes/import-progress for why).
module Imports
  class ProgressBroadcaster
    def initialize(import)
      @import = import
    end

    def call
      SpreadsheetImportChannel.broadcast_to(import, import.summary_json)
    end

    private
      attr_reader :import
  end
end
