class AddLocaleToAdmins < ActiveRecord::Migration
  def change
    add_column :admins, :locale, :string, limit: 5, null: false, default: 'fi'
  end
end
