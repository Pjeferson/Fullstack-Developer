class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one_attached :avatar_image, dependent: :purge_later
  belongs_to :spreadsheet_import, optional: true

  enum :role, { default: 0, admin: 1 }, default: :default

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, presence: true

  def avatar_url
    return unless avatar_image.attached?

    Rails.application.routes.url_helpers.rails_blob_path(avatar_image, only_path: true)
  end

  # The shape a User is rendered as wherever their profile is shown or
  # edited — the admin user list/edit forms and the self-service profile
  # page both use this, so the two stay in sync automatically.
  def profile_json
    as_json(only: %i[id email_address full_name role avatar_processing avatar_error], methods: %i[avatar_url])
  end
end
