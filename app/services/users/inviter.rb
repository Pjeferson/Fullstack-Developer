module Users
  # Creates a User without a real password and emails them the existing
  # password-reset flow to let them set their own. Kept as a service
  # rather than a User.invite class method so user creation doesn't
  # inherently couple to "always sends an email" — a future bulk import
  # (spreadsheet import) will likely want to create users without
  # individually emailing each one.
  class Inviter
    def initialize(email_address:, full_name:)
      @email_address = email_address
      @full_name = full_name
    end

    def call
      user = User.new(email_address: email_address, full_name: full_name)
      user.password = SecureRandom.hex(32) # satisfies has_secure_password; never usable as-is
      PasswordsMailer.reset(user).deliver_later if user.save
      user
    end

    private
      attr_reader :email_address, :full_name
  end
end
