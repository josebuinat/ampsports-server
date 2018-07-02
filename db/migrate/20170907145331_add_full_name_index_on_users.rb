class AddFullNameIndexOnUsers < ActiveRecord::Migration
  def up
    execute "CREATE INDEX index_users_full_name ON users ((trim(both ' ' from first_name) || ' ' || trim(both ' ' from last_name)))"
  end

  def down
    execute "DROP INDEX index_users_full_name"
  end
end
