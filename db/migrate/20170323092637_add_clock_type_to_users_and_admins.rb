class AddClockTypeToUsersAndAdmins < ActiveRecord::Migration
  def change
    add_column :users, :clock_type, :integer, null: false, default: 1
    add_column :admins, :clock_type, :integer, null: false, default: 1
  end
end
