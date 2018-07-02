class AddCoachColorsToVenue < ActiveRecord::Migration
  def change
    add_column :venues, :coach_colors, :text
  end
end
