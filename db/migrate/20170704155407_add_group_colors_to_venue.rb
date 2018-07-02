class AddGroupColorsToVenue < ActiveRecord::Migration
  def change
    add_column :venues, :group_colors, :text
  end
end
