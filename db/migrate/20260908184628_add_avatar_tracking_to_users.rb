class AddAvatarTrackingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :avatar_processing, :boolean, null: false, default: false
    add_column :users, :avatar_error, :string
  end
end
