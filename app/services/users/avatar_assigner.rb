module Users
  # Attaches a User's avatar_image, either synchronously from an uploaded
  # file or asynchronously by downloading a remote URL (see
  # AttachRemoteAvatarJob). Never trust the caller's file/url blindly:
  # content-type and size are validated here (and re-validated after
  # download, for the URL path).
  class AvatarAssigner
    ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
    MAX_SIZE = 5.megabytes

    def initialize(user, file: nil, url: nil)
      @user = user
      @file = file
      @url = url
    end

    # Returns true on success (including "nothing to do"). Returns false
    # and adds to user.errors[:avatar_image] if the upload was rejected.
    # Must be called after the caller's own user.update(...)/valid? call,
    # since ActiveRecord validations clear errors at the start of their run.
    def call
      return true if file.blank? && url.blank?

      file.present? ? attach_file : enqueue_download
    end

    private
      attr_reader :user, :file, :url

      def attach_file
        return reject("must be PNG, JPEG, WEBP, or GIF") unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
        return reject("must be smaller than 5MB") if file.size > MAX_SIZE

        user.avatar_image.attach(file)
        user.update!(avatar_processing: false, avatar_error: nil)
        true
      end

      def enqueue_download
        user.update!(avatar_processing: true, avatar_error: nil)
        AttachRemoteAvatarJob.perform_later(user.id, url)
        true
      end

      def reject(message)
        user.errors.add(:avatar_image, message)
        false
      end
  end
end
