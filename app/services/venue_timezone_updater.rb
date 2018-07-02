# Timezone fetching service. Sets or updates venue's timezone
class VenueTimezoneUpdater
  attr_reader :venue

  def initialize(venue)
    @venue = venue
  end

  def set_timezone
    timezone = fetch_timezone venue
    venue.timezone = timezone
  end

  def update_timezone
    timezone = fetch_timezone venue
    venue.update(timezone: timezone.to_s)
  end

  private

  def fetch_timezone(venue)
    begin
      Timezone.lookup(venue.latitude, venue.longitude)
    rescue Timezone::Error::GeoNames, Timezone::Error::InvalidZone => e
      Rollbar.error(e, 'Error while fetching timezone',
                    venue_id: venue.id,
                    geo_position: "lat: #{venue.latitude}, lon: #{venue.longitude}"
      )
      nil
    end
  end
end
