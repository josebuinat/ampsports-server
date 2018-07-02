class AddStatusToVenue < ActiveRecord::Migration
  def change
    add_column :venues, :status, :integer, default: Venue.statuses[:hidden], null: false
  end
end
