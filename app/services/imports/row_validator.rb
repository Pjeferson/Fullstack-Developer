# Checks a single import row's raw data before it's ever considered for insertion. This is
# deliberately not a reuse of User's own model validations (see design.md) — has_secure_password
# bakes a "password must be present" check into its own macro that can't be scoped off for this
# import-only path, so this validator checks the same underlying rules (email format, full name
# presence, valid role) as plain Ruby against the row Hash, with no User instance involved.
module Imports
  class RowValidator
    def initialize(row)
      @row = row
    end

    def valid?
      errors.empty?
    end

    def errors
      @errors ||= [].tap do |errs|
        errs << "email is invalid" unless valid_email?
        errs << "full name can't be blank" if full_name.blank?
        errs << "role is invalid" unless valid_role?
      end
    end

    private
      attr_reader :row

      def email
        row["email_address"].to_s.strip.downcase
      end

      def full_name
        row["full_name"].to_s.strip
      end

      def role
        row["role"].to_s.strip
      end

      def valid_email?
        email.present? && email.match?(URI::MailTo::EMAIL_REGEXP)
      end

      def valid_role?
        role.blank? || User.roles.key?(role)
      end
  end
end
