class AddAllowOverlappingResellToVenue < ActiveRecord::Migration
  def change
    add_column :venues, :allow_overlapping_resell, :boolean, default: false
  end
end
