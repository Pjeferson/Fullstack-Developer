require "test_helper"
require "capybara/playwright"

# playwright_cli_executable_path points at the local node_modules install directly rather than
# the gem's own "npx playwright" default - avoids npx's resolution/download overhead on every
# browser launch, and pins exactly which install runs. HEADLESS=false lets a real run be watched
# locally (e.g. `HEADLESS=false bin/rails test test/system/sessions_test.rb`). BROWSER selects
# which of Playwright's three engines drives the suite - chromium (Chrome/Edge), firefox, or
# webkit (Safari's engine) - defaulting to chromium, same as every run before this existed.
Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: ENV.fetch("BROWSER", "chromium").to_sym,
    headless: ENV["HEADLESS"] != "false",
    playwright_cli_executable_path: Rails.root.join("node_modules/.bin/playwright").to_s
  )
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ActiveJob::TestHelper

  driven_by :playwright

  # config/cable.yml's test adapter stays "test" (the Rails default, built for
  # ActionCable::TestHelper's assert_broadcast_on/assert_has_stream) - system tests are the one
  # place that needs a real browser to actually receive a broadcast over its own WebSocket
  # connection, so only this class switches to "async" (a real, in-process pub/sub), via
  # ActionCable's own public config/restart API rather than a global config change or reaching
  # into a private ivar.
  setup do
    ActionCable.server.config.cable = { "adapter" => "async" }
    ActionCable.server.restart
  end

  # Playwright's fill/type dispatches real DOM events and returns as soon as the browser has
  # processed them - it doesn't wait for React's own (async) state commit and re-render that
  # follows. Clicking a submit button immediately after filling a controlled input can race
  # ahead of that commit, so this app's client-side isValid check (see useValidation) can still
  # see a field as empty and block a submit that should have gone through - confirmed by hand
  # this only happens without a pause here, never with one. Not a fix for an app bug: a real
  # person's fingers are never this fast between typing and clicking.
  def settle_after_fill!
    sleep 0.5
  end
end
