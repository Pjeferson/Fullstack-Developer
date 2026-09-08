class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one_attached :avatar_image, dependent: :purge_later

  enum :role, { default: 0, admin: 1 }, default: :default

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, presence: true

  def avatar_url
    return unless avatar_image.attached?

    Rails.application.routes.url_helpers.rails_blob_path(avatar_image, only_path: true)
  end
end
