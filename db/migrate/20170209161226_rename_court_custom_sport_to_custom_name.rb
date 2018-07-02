class RenameCourtCustomSportToCustomName < ActiveRecord::Migration
  def change
    rename_column :courts, :custom_sport_name, :custom_name
    add_column :courts, :private, :boolean, default: false
  end
end
