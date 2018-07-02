class AddIndexToPolymorphicOwners < ActiveRecord::Migration
  def change
    add_index :memberships, [:user_id, :user_type]
    add_index :reservations, [:user_id, :user_type]
  end
end
