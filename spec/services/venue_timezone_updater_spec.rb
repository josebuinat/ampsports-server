require 'rails_helper'

describe VenueTimezoneUpdater do
  let(:venue) { build :venue }
  let(:updater) { VenueTimezoneUpdater.new(venue) }

  describe '#set_timezone' do
    it 'sets venue timezone' do
      VCR.use_cassette('venue_timezone_lookup') do
        updater.set_timezone
      end
      expect(venue.timezone).to be
    end

    it 'sends an error to Rollbar if fails to reverse geocode' do
      expect(Timezone).to receive(:lookup).and_raise(Timezone::Error::GeoNames)
      expect(Rollbar).to receive(:error).with(
        instance_of(Timezone::Error::GeoNames),
        'Error while fetching timezone',
        {
          venue_id: nil,
          geo_position: "lat: #{venue.latitude}, lon: #{venue.longitude}"
        }
      )
      updater.set_timezone
    end
  end

  describe '#update_timezone' do
    it 'updates venue timezone' do
      expect(venue).to receive(:update).with(timezone: 'America/Los_Angeles')
      VCR.use_cassette('venue_timezone_lookup') do
        updater.update_timezone
      end
    end
  end
end