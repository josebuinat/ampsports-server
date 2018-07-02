class CreateUserPermission < ActiveRecord::Migration
  def change
    create_table :user_permissions do |t|
      t.belongs_to  :owner, polymorphic: true, index: true, null: false

      t.string      :permission, null: false
      t.string      :value, null: false

      t.timestamps null: false
    end

    remove_column :coaches, :permissions, :text
    remove_column :admins, :permissions, :text
  end
end
