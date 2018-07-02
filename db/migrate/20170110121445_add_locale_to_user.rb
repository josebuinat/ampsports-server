class AddLocaleToUser < ActiveRecord::Migration
  def change
    add_column :users, :locale, :string, null: false, default: 'fi'
  end
end
