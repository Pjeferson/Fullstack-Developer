require "test_helper"

class SpreadsheetImportChannelTest < ActionCable::Channel::TestCase
  setup do
    @import = SpreadsheetImport.create!(admin: users(:admin))
  end

  test "an admin subscribing to an existing import streams for it" do
    stub_connection current_user: users(:admin)

    subscribe(id: @import.id)

    assert subscription.confirmed?
    assert_has_stream_for @import
  end

  test "a non-admin is rejected" do
    stub_connection current_user: users(:one)

    subscribe(id: @import.id)

    assert subscription.rejected?
  end

  test "subscribing with a nonexistent import id is rejected" do
    stub_connection current_user: users(:admin)

    subscribe(id: -1)

    assert subscription.rejected?
  end
end
