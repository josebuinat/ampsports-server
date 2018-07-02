require 'rails_helper'

# Both Search::OnVenue and Search::Global share same core;
# Therefore, Search::Global is tested much more extensively and this spec
# Just ensures general ability to perform it's tasks
describe Search::OnVenue, type: :service do
  let!(:venue) { create :venue, :searchable, courts: courts }
  let(:courts) { [ court_1, court_2, court_3 ] }
  let(:court_1) { create :court, :with_prices, sport_name: :tennis }
  let(:court_2) { create :court, :with_prices, sport_name: :tennis }
  let(:court_3) { create :court, :with_prices, sport_name: :golf }
  let(:sport_name_param) { 'tennis' }
  let(:date_param) { Time.current.tomorrow }
  let(:search_instance) do
    described_class.new(sport_name: sport_name_param, date: date_param, venue: venue.id).call
  end

  describe '#venue' do
    subject { search_instance.venue }
    it 'returns the venue' do
      is_expected.to eq venue
    end
  end

  describe '#courts' do
    subject { search_instance.courts }

    context 'when sport is tennis' do
      it 'returns correct courts' do
        is_expected.to match_array [court_1, court_2]
      end
    end

    context 'when sport is golf' do
      let(:sport_name_param) { 'golf' }
      it 'returns correct courts' do
        is_expected.to eq [court_3]
      end
    end

    context 'when one court is fully booked' do
      let(:tomorrow_in_venue_tz) { Date.current.tomorrow }
      let(:reservation_start_date) { in_venue_tz { date_param.to_datetime.in_time_zone.change(hour: 6) } }
      let(:reservation_end_date) { in_venue_tz { date_param.to_datetime.in_time_zone.change(hour: 22, minute: 00) } }
      let!(:reservation) do
        create :reservation,
               start_time: reservation_start_date,
               end_time: reservation_end_date,
               court: court_1
      end

      it 'still renders it' do
        is_expected.to match_array [court_1, court_2]
      end
    end

    context 'when one court does not have pricing' do
      let(:court_2) { create :court, sport_name: :tennis }
      it 'does not render it' do
        is_expected.to eq [court_1]
      end
    end

    context 'connected venues' do
      let!(:venue2) { create :venue, :searchable, :with_courts }

      before(:each) do
        venue.connect_venue(venue2)
      end

      it 'returns courts from both venues' do
        is_expected.to match_array([court_1, court_2] + venue2.courts)
      end
    end
  end
end
