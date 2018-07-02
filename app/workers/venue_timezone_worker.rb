class VenueTimezoneWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(venue_id)
    venue = Venue.find_by(id: venue_id)
    VenueTimezoneUpdater.new(venue).update_timezone
  end
end
