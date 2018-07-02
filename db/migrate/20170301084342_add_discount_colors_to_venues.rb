class AddDiscountColorsToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :discount_colors, :text
  end
end
