# Inserts one batch of already-parsed spreadsheet rows as Users via a single insert_all,
# instead of a User.new(...).save per row (see design.md for why: throughput on large files,
# at the cost of AR callbacks/validations, which Imports::RowValidator substitutes for).
module Imports
  class UserBatchInserter
    # `inserted` is an Array of `{ id:, email_address: }` for rows that actually made it into
    # the table (not skipped by ON CONFLICT) — the job needs the id to enqueue a per-row avatar
    # download job.
    Result = Struct.new(:inserted_count, :failed_rows, :inserted, keyword_init: true)

    def initialize(rows)
      @rows = rows
    end

    def call
      valid_rows, invalid_rows = rows.partition { |row| RowValidator.new(row).valid? }
      failed_rows = invalid_rows.map { |row| [ row, RowValidator.new(row).errors.join(", ") ] }

      return Result.new(inserted_count: 0, failed_rows: failed_rows, inserted: []) if valid_rows.empty?

      inserted = insert(valid_rows)
      inserted_emails = inserted.map { |row| row[:email_address] }
      duplicates = valid_rows.reject { |row| inserted_emails.include?(email_for(row)) }
      failed_rows += duplicates.map { |row| [ row, "email already in use" ] }

      Result.new(inserted_count: inserted.size, failed_rows: failed_rows, inserted: inserted)
    end

    private
      attr_reader :rows

      # One bcrypt hash for the whole batch, not once per row (bcrypt is deliberately slow) and
      # not once for the whole job (every User in the file sharing a single digest is an
      # unnecessary audit smell). Never usable as-is — same semantics as Users::Inviter.
      def insert(valid_rows)
        digest = BCrypt::Password.create(SecureRandom.hex(32))
        attributes = valid_rows.map { |row| attributes_for(row, digest) }

        result = User.insert_all(attributes, returning: %i[id email_address], unique_by: :index_users_on_email_address)
        result.rows.map { |(id, email_address)| { id: id, email_address: email_address } }
      end

      def attributes_for(row, digest)
        {
          email_address: email_for(row),
          full_name: row["full_name"].to_s.strip,
          role: User.roles.fetch(role_key_for(row)),
          password_digest: digest
        }
      end

      def email_for(row)
        row["email_address"].to_s.strip.downcase
      end

      def role_key_for(row)
        row["role"].to_s.strip.presence || "default"
      end
  end
end
