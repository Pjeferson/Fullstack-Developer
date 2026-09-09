class AddIndexToUsersRole < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :role
  end
end
