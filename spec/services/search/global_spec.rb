require 'rails_helper'

describe Search::Global, type: :service do

  let(:search_instance) do
    described_class.new(
      sport_name: sport_name_param,
      time: time_param,
      location: location_param,
      duration: duration_param,
      date: date_param,
      sort_by: sort_by_param
    ).call
  end

  let(:sport_name_param) { 'tennis' }
  let(:duration_param) { 60 }
  let(:date_param) { Date.tomorrow }
  let(:location_param) { nil }
  let(:sort_by_param) { nil }
  let(:time_param) { '1700' }

  # There's 2 essential methods to test:
  # Test search_instance.venues to make sure only appropriate venues are returned;
  # Test #available_courts_for(venue) to make sure only appropriate courts are returned
  # For easier understanding, consider this output format to the client:
  # [ {venue: venue, courts: available_courts_for(venue)} ]
  describe 'venues' do
    subject { search_instance.venues }
    let!(:foo_venue) { create :venue, :searchable, courts: [foo_court_1, foo_court_2], timezone: 'Europe/Helsinki' }
    let!(:bar_venue) { create :venue, :searchable, courts: [bar_court_1], timezone: 'Europe/Helsinki' }
    let(:foo_court_1) { create :court, :with_prices, sport_name: :tennis }
    let(:foo_court_2) { create :court, :with_prices, sport_name: :badminton }
    let(:bar_court_1) { create :court, :with_prices, sport_name: :tennis }

    context 'with prepopulated venues' do
      subject { search_instance.prepopulated_venues }
      let!(:foo_pre_venue) { create :venue, :prepopulated }
      let!(:bar_pre_venue) { create :venue, :prepopulated }

      # only tests prepopulated filter. Location filter is
      # the same used for searchable venues, tested on line
      # 195.
      it 'returns correct venues' do
        # we list also not prepopulated venues because we want to list them. That's not a mistake.
        is_expected.to match_array [foo_pre_venue, bar_pre_venue, foo_venue, bar_venue]
      end
    end

    context 'when at least one sport matches' do
      let(:sport_name_param) { 'tennis' }
      it 'returns that venue' do
        is_expected.to match_array [foo_venue, bar_venue]
      end
    end

    context 'when no sport matches' do
      let(:sport_name_param) { 'badminton' }
      it 'does not return that venue' do
        is_expected.to eq [foo_venue]
      end
    end

    context 'when courts has no price' do
      let(:foo_court_1) { create :court }
      it 'does not return that venue' do
        is_expected.to eq [bar_venue]
      end
    end

    context 'when venue is on holiday' do
      let!(:holiday) do
        Time.use_zone(courts.first.venue.timezone) do
          create :holiday,
                 start_time: date_param.to_datetime.in_time_zone.change(start_time),
                 end_time: date_param.to_datetime.in_time_zone.change(end_time),
                 courts: courts
        end
      end

      # make foo_court_2 tennis one to make it come up in a search
      let(:foo_court_2) { create :court, :with_prices, sport_name: :tennis }

      context 'when whole day is on holiday' do
        let(:start_time) { { hour: 3 } }
        let(:end_time) { { hour: 23, minute: 59 } }
        context 'when both courts are on holiday' do
          let(:courts) { [foo_court_1, foo_court_2] }
          it 'does not come up in a search' do
            is_expected.to eq [bar_venue]
          end
        end

        context 'when one court is on holiday and the other is working' do
          let(:courts) { [foo_court_1] }
          it 'comes up in a search' do
            is_expected.to match_array [foo_venue, bar_venue]
          end
        end
      end

      context 'when part of the day is on holiday' do
        let(:start_time) { { hour: 12 } }
        let(:end_time){ { hour: 23, minute: 59 } }
        let(:courts) { [foo_court_1, foo_court_2] }
        it 'come up in a search' do
          is_expected.to match_array [bar_venue, foo_venue]
        end


        context 'when other part is fully booked' do
          let(:courts) { [bar_court_1] }
          # day starts | reservation <-> reservation <-> holiday | day ends
          let(:reservation_start_date) { date_param.to_datetime.in_time_zone.change(hour: 6) }
          let(:reservation_end_date) { date_param.to_datetime.in_time_zone.change(hour: 10) }
          let!(:reservation_1) { create :reservation,
                                        start_time: reservation_start_date,
                                        end_time: reservation_end_date,
                                        court: bar_court_1
          }
          let!(:reservation_2) { create :reservation,
                                        start_time: reservation_end_date,
                                        end_time: date_param.to_datetime.in_time_zone.change(start_time),
                                        court: bar_court_1
          }

          it 'does not come up in a search' do
            is_expected.to eq [foo_venue]
          end
        end
      end
    end

    context 'when venue is booked' do
      let!(:reservation) do
        create :reservation,
               start_time: reservation_start_date,
               end_time: reservation_end_date,
               court: bar_court_1
      end

      context 'when it is fully booked' do
        let(:reservation_start_date) { date_param.to_datetime.in_time_zone.change(hour: 6) }
        let(:reservation_end_date) { date_param.to_datetime.in_time_zone.change(hour: 22, minute: 00) }
        it 'does not come up in a search' do
          is_expected.to eq [foo_venue]
        end

        context 'with free courts' do
          let!(:new_venue) { create :court, :with_prices, venue: bar_venue }
          it 'comes up in a search' do
            is_expected.to match_array [foo_venue, bar_venue]
          end
        end
      end

      context 'when it is partially booked' do
        let(:reservation_start_date) { date_param.to_datetime.in_time_zone.change(hour: 15) }
        let(:reservation_end_date) { date_param.to_datetime.in_time_zone.change(hour: 16) }

        it 'comes up in a search' do
          is_expected.to match_array [foo_venue, bar_venue]
        end
      end
    end


    # TODO: same for courts
    describe 'different durations' do
      let(:foo_court_1) do
        create :court, :with_prices,
               sport_name: :tennis,
               duration_policy: foo_court_1_duration_policy
      end
      let(:foo_court_2) do
        create :court, :with_prices,
               sport_name: :badminton,
               duration_policy: foo_court_2_duration_policy
      end
      let(:bar_court_1) do
        create :court, :with_prices,
               sport_name: :tennis,
               duration_policy: bar_court_1_duration_policy
      end

      let(:foo_court_2_duration_policy) { :one_hour }
      let(:bar_court_1_duration_policy) { :one_hour }
      let(:foo_court_1_duration_policy) { :any_duration }

      context 'with 30 minutes duration policy' do
        let(:duration_param) { 30 }
        it 'returns only any duration venues' do
          is_expected.to eq [foo_venue]
        end
      end

      context 'with only one hour policy' do
        let(:foo_court_2_duration_policy) { :two_hour }
        let(:bar_court_1_duration_policy) { :one_hour }
        let(:duration_param) { 60 }
        it 'returns one hour duration AND any duration' do
          is_expected.to match_array [bar_venue, foo_venue]
        end
      end

      context 'with only two hours policy' do
        let(:foo_court_2_duration_policy) { :one_hour }
        let(:bar_court_1_duration_policy) { :two_hour }
        let(:duration_param) { 120 }
        it 'returns only two hour duration AND any duration' do
          is_expected.to match_array [bar_venue, foo_venue]
        end
      end
    end

    describe 'locations' do
      # street represents "position slightly more kilometers from Helsinki"
      # @see support/geocoder.rb
      let!(:foo_venue) { create :venue, :searchable, :with_courts, street: 'five', city: 'Helsinki', zip: '00100' }
      let!(:buzz_venue) { create :venue, :searchable, :with_courts, street: 'twelve', city: 'Helsinki', zip: '00100' }
      let!(:bar_venue) { create :venue, :searchable, :with_courts, street: 'twenty', city: 'Helsinki', zip: '00100' }
      let(:city_name) { 'Helsinki, Finland' }
      let(:location_param) { { city_name: city_name } }

      before do
        allow_any_instance_of(Search::Global).to receive(:location_radius).and_return(location_radius)
      end

      describe 'filtering far away ones' do
        let(:location_radius) { 20 }
        it 'filters out venues which are too far away' do
          is_expected.to match_array [foo_venue, buzz_venue]
        end
      end

      describe 'sorting by distance' do
        let(:sort_by_param) { 'distance' }
        # find all venues, test sorting
        let(:location_radius) { 100 }

        it 'returns sorted set' do
          is_expected.to eq [foo_venue, buzz_venue, bar_venue]
        end
      end

      describe 'when country is set' do
        let(:usa_company) { create :usa_company }
        let!(:usa_venue) { create :venue, :searchable, :with_courts, company: usa_company }
        let(:location_param) { { country: 'US' } }
        let(:location_radius) { 100 }

        it 'returns one venue from USA' do
          is_expected.to eq [usa_venue]
        end
      end
    end

    describe 'sorting by price' do
      let(:sort_by_param) { 'price' }

      let(:foo_court_1) { create :court }
      let(:foo_court_2) { create :court }
      let(:bar_court_1) { create :court }
      let!(:buzz_venue) { create :venue, :searchable, courts: [buzz_court] }
      let(:buzz_court) { create :court }

      # TODO: enhance this test (and code) to account what time user seeks for
      let!(:foo_court_1_price) { create :filled_price, courts: [foo_court_1], price: 20 }
      let!(:foo_court_2_price) { create :filled_price, courts: [foo_court_2], price: 5 }
      let!(:bar_court_price) { create :filled_price, courts: [bar_court_1], price: 10 }
      let!(:buzz_price) { create :filled_price, courts: [buzz_court], price: 2 }

      it 'sorts it depending on the price' do
        is_expected.to eq [buzz_venue, foo_venue, bar_venue]
      end
    end

    describe 'sorting by availability' do
      let(:sort_by_param) { 'availability' }
      let(:buzz_venue) { create :venue, :searchable, :with_courts, court_count: 2 }
      # looking for a game from 17 to 18
      let(:date_param_in_timezone) { date_param.to_datetime.in_time_zone }
      let(:reservation_1_start_date) { date_param_in_timezone.change(hour: 17) }
      let(:reservation_1_end_date) { date_param_in_timezone.change(hour: 18) }
      let(:reservation_2_start_date) { date_param_in_timezone.change(hour: 17, min: 30) }
      let(:reservation_2_end_date) { date_param_in_timezone.change(hour: 18, min: 30) }

      # second court is still free; buzz_venue should be first
      let!(:buzz_reservation) do
        create :reservation, start_time: reservation_1_start_date,
          end_time: reservation_1_end_date, court: buzz_venue.courts.first
      end

      # foo_court_2 is for badminton, so this one will go last
      let!(:foo_reservation) do
        create :reservation,
               start_time: reservation_2_start_date,
               end_time: reservation_2_end_date,
               court: foo_court_1
      end

      it 'works' do
        expect(subject[0..1]).to match_array [buzz_venue, bar_venue]
        expect(subject[2]).to eq foo_venue
      end

    end

    context 'connected venues with page limit' do
      let!(:baz_venue) { create :venue, :searchable, :with_courts }

      let(:search_instance) do
        described_class.new(
          sport_name: sport_name_param,
          time: time_param,
          location: location_param,
          duration: duration_param,
          date: date_param,
          sort_by: sort_by_param,
          per_page: 1
        ).call
      end

      context 'without connected venue' do
        it 'returns only venues within page limit' do
          expect(subject.count).to eq 1
        end
      end

      context 'with connected venue' do
        before(:each) do
          bar_venue.destroy #we want only one venue on page
          foo_venue.connect_venue(baz_venue)
        end

        it 'returns connected venues outside of page limit' do
          is_expected.to match_array([foo_venue, baz_venue])
        end
      end
    end
  end

  describe 'available_courts_for' do
    subject { search_instance.available_courts_for(foo_venue) }
    let!(:foo_venue) { create :venue, :searchable, courts: [foo_court_1, foo_court_2] }
    let(:foo_court_1) { create :court, :with_prices, sport_name: :tennis }
    let(:foo_court_2) { create :court, :with_prices, sport_name: :badminton }

    it 'does not return wrong courts' do
      is_expected.to eq [foo_court_1]
    end

    context 'connected venues' do
      let!(:baz_venue) { create :venue, :searchable, :with_courts }

      before(:each) do
        foo_venue.connect_venue(baz_venue)
      end

      it 'returns courts from venue and connected venue' do
        is_expected.to match_array([foo_court_1] + baz_venue.courts)
      end
    end
  end

  describe 'all_courts' do
    subject { search_instance.all_courts }
    let!(:foo_venue) { create :venue, :searchable, courts: [foo_court_1, foo_court_2] }
    let!(:bar_venue) { create :venue, :searchable, courts: [bar_court_1] }
    let(:foo_court_1) { create :court, :with_prices, sport_name: :tennis }
    let(:foo_court_2) { create :court, :with_prices, sport_name: :badminton }
    let(:bar_court_1) { create :court, :with_prices, sport_name: :tennis }

    it 'does not return extra courts' do
      is_expected.to match_array [foo_court_1, bar_court_1]
    end

    context 'connected venues with page limit' do
      let!(:baz_venue) { create :venue, :searchable, :with_courts }
      let(:search_instance) do
        described_class.new(sport_name: sport_name_param, time: time_param,
          location: location_param, duration: duration_param, date: date_param,
          sort_by: sort_by_param, per_page: 1).call
      end

      before(:each) do
        bar_venue.destroy #we want only one venue on page
        foo_venue.connect_venue(baz_venue)
      end

      it 'returns courts from venues, and from connected venues outside of page limit' do
        is_expected.to match_array([foo_court_1] + baz_venue.courts)
      end
    end
  end

  describe 'error' do
    subject { search_instance.error }

    let!(:venue) { create :venue, :searchable, :with_courts,
                          court_count: 1,
                          timezone: 'Europe/Helsinki'
    }
    let(:court) { venue.courts.first }
    context 'when everything is good' do
      it 'renders no error' do
        is_expected.to be_nil
      end
    end

    context 'when no results found' do
      let(:sport_name_param) { 'golf' }
      it 'says that nothing found' do
        is_expected.to eq :nothing_found
      end
    end

    context 'when everything is booked' do
      let(:reservation_start_date) { date_param.to_datetime.in_time_zone.change(hour: 6) }
      let(:reservation_end_date) { date_param.to_datetime.in_time_zone.change(hour: 22) }
      let!(:reservation_1) do
        create :reservation,
               start_time: reservation_start_date,
               end_time: reservation_end_date,
               court: court
      end

      it 'says all booked' do
        is_expected.to eq :all_booked
      end
    end
  end
end
