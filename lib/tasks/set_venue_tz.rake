namespace :tz do
  desc 'Set venue timezone based on its location.'
  task set_venue_tz: :environment do
    venues = Venue.where(timezone: nil).take(5)
    venues.each do |venue|
      VenueTimezoneUpdater.new(venue).update_timezone
    end
  end
end
