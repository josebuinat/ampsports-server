class AddTimezoneToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :timezone, :string, default: 'Europe/Helsinki', null: false
  end
end
