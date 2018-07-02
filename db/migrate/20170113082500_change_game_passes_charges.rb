class ChangeGamePassesCharges < ActiveRecord::Migration
  def change
    change_column :game_passes, :total_charges, :decimal, precision: 8, scale: 3
    change_column :game_passes, :remaining_charges, :decimal, precision: 8, scale: 3
  end
end
