class ChangeMembershipUserToPolymorphic < ActiveRecord::Migration
  def up
    add_column :memberships, :user_type, :string

    execute("UPDATE memberships SET user_type = 'User'")
  end

  def down
    remove_column :memberships, :user_type, :string
  end
end
