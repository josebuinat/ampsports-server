class AddPermissionsToAdminAndCoach < ActiveRecord::Migration
  def change
    add_column :coaches, :permissions, :text
    add_column :admins, :permissions, :text
  end
end
