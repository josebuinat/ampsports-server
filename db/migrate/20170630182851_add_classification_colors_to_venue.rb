class AddClassificationColorsToVenue < ActiveRecord::Migration
  def change
    add_column :venues, :classification_colors, :text
  end
end
