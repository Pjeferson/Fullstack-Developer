require "test_helper"

module Admin
  class UsersQueryTest < ActiveSupport::TestCase
    setup do
      User.delete_all
      # 30 Users, ids ascending with creation order — @users.last is newest.
      @users = 30.times.map { |i| User.create!(email_address: "user#{i}@example.com", full_name: "User #{i}", password: "password") }
    end

    test "the first page returns the 25 newest Users" do
      records = UsersQuery.new.records

      assert_equal @users.last(25).reverse.map(&:id), records.map(&:id)
    end

    test "next_page is the 26th User's id when more Users exist" do
      query = UsersQuery.new
      query.records

      assert_equal @users[5].id, query.metadata[:next_page]
    end

    test "next_page is nil when exhausted" do
      query = UsersQuery.new(before_id: @users[4].id)
      query.records

      assert_nil query.metadata[:next_page]
    end

    test "passing before_id returns the next 25 older than that id" do
      records = UsersQuery.new(before_id: @users[5].id).records

      assert_equal @users.first(5).reverse.map(&:id), records.map(&:id)
    end

    test "a User created after an earlier page was fetched doesn't appear again or shift a later page" do
      first_page = UsersQuery.new.records
      before_id = first_page.last.id

      User.create!(email_address: "late-arrival@example.com", full_name: "Late Arrival", password: "password")

      second_page = UsersQuery.new(before_id: before_id).records

      assert_equal @users.first(5).reverse.map(&:id), second_page.map(&:id)
    end
  end
end
