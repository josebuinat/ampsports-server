class RemoveListedFromVenue < ActiveRecord::Migration
  def change
    remove_column :venues, :listed, :boolean, default: false
  end
end
