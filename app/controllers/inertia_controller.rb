# frozen_string_literal: true

class InertiaController < ApplicationController
  # Share data with all Inertia responses
  # see https://inertia-rails.dev/guide/shared-data
  inertia_share do
    { current_user: Current.user&.as_json(only: %i[id email_address role]) }
  end
end
