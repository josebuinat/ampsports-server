class AddPriceToGroupSeasons < ActiveRecord::Migration
  def change
    add_column :group_seasons, :participation_price, :decimal, precision: 8, scale: 2
  end
end
