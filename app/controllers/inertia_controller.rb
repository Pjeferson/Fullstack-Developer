# frozen_string_literal: true

class InertiaController < ApplicationController
  # Share data with all Inertia responses
  # see https://inertia-rails.dev/guide/shared-data
  inertia_share do
    {
      current_user: Current.user&.as_json(only: %i[id email_address role]),
      # Plain Rails flash (redirect_to ..., notice:/alert:), not inertia_rails' own separate
      # flash.inertia[...] scope (see FlashExtension) - nothing bridges the two automatically,
      # so every redirect_to ..., alert/notice: across this app silently never reached the
      # frontend's usePage().props.flash until this was added.
      flash: { notice: flash[:notice], alert: flash[:alert] }
    }
  end
end
