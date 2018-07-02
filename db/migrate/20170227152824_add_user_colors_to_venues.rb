class AddUserColorsToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :user_colors, :text
  end
end
