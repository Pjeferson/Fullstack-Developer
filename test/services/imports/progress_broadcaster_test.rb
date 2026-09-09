require "test_helper"

module Imports
  class ProgressBroadcasterTest < ActiveSupport::TestCase
    include ActionCable::TestHelper

    test "broadcasts the import's current summary_json" do
      import = SpreadsheetImport.create!(admin: users(:admin), status: :processing, processed_rows: 3)

      assert_broadcast_on(SpreadsheetImportChannel.broadcasting_for(import), import.summary_json) do
        ProgressBroadcaster.new(import).call
      end
    end
  end
end
