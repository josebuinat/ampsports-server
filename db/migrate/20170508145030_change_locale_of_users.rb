class ChangeLocaleOfUsers < ActiveRecord::Migration
  def up
    change_column :users, :locale, :string, default: :en, null: false
  end

  def down
    change_column :users, :locale, :string, default: :fi, null: false
  end
end
