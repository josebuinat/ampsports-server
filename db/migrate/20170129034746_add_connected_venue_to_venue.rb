class AddConnectedVenueToVenue < ActiveRecord::Migration
  def change
    add_column :venues, :connected_venue_id, :integer

    add_index(:venues, :connected_venue_id)
  end
end
