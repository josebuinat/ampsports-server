class AddBookingLimitsToVenue < ActiveRecord::Migration
  def change
    add_column :venues, :max_consecutive_bookable_hours, :integer
    add_column :venues, :max_bookable_hours_per_day, :integer
  end
end
