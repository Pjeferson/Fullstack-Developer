# Downloads a remotely-hosted avatar image and attaches it to a User.
# Runs async (not inline in the request) since it's an unbounded outbound
# HTTP call to a host we don't control. Uses ssrf_filter so the URL can't
# be used to reach internal/private network addresses, including via a
# redirect chain.
class AttachRemoteAvatarJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound
  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 3

  def perform(user_id, url)
    user = User.find(user_id)

    begin
      response = SsrfFilter.get(url)

      content_type = response["content-type"]
      raise "unsupported content type: #{content_type.inspect}" unless
        Users::AvatarAssigner::ALLOWED_CONTENT_TYPES.include?(content_type)
      raise "file too large" if response.body.bytesize > Users::AvatarAssigner::MAX_SIZE

      user.avatar_image.attach(
        io: StringIO.new(response.body),
        filename: File.basename(URI.parse(url).path).presence || "avatar",
        content_type: content_type
      )
      user.update!(avatar_processing: false, avatar_error: nil)
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise # transient — let retry_on above handle it
    rescue SsrfFilter::Error, StandardError => e
      # Permanent failure (blocked IP, bad content-type, oversized, DNS
      # failure, ...) — record it, don't retry.
      user.update!(avatar_processing: false, avatar_error: "Could not download image: #{e.message}")
    end
  end
end
