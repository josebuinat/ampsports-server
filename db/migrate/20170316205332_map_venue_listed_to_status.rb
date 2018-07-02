class MapVenueListedToStatus < ActiveRecord::Migration
  def up
    Venue.where(listed: true).update_all(status: Venue.statuses[:searchable])
    Venue.where(listed: false).update_all(status: Venue.statuses[:hidden])
  end

  def down
    Venue.where(status: Venue.statuses[:searchable]).update_all(listed: true)
    Venue.where(status: Venue.statuses[:hidden]).update_all(listed: false)
  end
end
