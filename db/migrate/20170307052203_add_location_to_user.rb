class AddLocationToUser < ActiveRecord::Migration
  def change
    add_column :users, :longitude, :decimal
    add_column :users, :latitude, :decimal
  end
end
