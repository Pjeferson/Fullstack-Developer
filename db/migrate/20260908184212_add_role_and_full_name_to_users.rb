class AddRoleAndFullNameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :integer, null: false, default: 0
    add_column :users, :full_name, :string, null: false, default: ""
  end
end
