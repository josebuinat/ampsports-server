require 'rails_helper'

shared_examples 'a correct duration spitter for global search' do |duration_to_set, price|
  let(:duration) { duration_to_set }
  let(:expected_start_at) do
    Time.use_zone(Venue.find(parsed_venue[:id]).timezone) do
      Time.zone.parse(date).change(hour: 6, minute: 0, second: 0)
    end
  end
  let(:expected_ends_at) do
    Time.use_zone(Venue.find(parsed_venue[:id]).timezone) do
      expected_start_at.advance(minutes: duration)
    end
  end
  it 'has available times' do
    # just many times, no matter how many
    # (it should be covered by #court.available_times)
    expect(available_times.size).to be > 15
    expect(received_start_at).to eq expected_start_at
    expect(received_ends_at).to eq expected_ends_at
    expect(received_price).to eq price
    expect(received_duration).to eq duration
  end
end

# assert mostly schema here and that duration in available_times is correct
describe API::SearchController, type: :controller do
  render_views
  let(:parsed_body) { JSON.parse(subject.body).with_indifferent_access }

  describe 'GET #venues' do
    let!(:foo_venue) { create :venue, :searchable }
    let!(:bar_venue) { create :venue, :searchable }
    let!(:foo_court_1) { create :court, :with_prices, sport_name: :tennis, duration_policy: :any_duration, venue: foo_venue }
    let!(:foo_court_2) { create :court, :with_prices, sport_name: :badminton, duration_policy: :one_hour, venue: foo_venue }
    let!(:bar_court_1) { create :court, :with_prices, sport_name: :tennis, duration_policy: :any_duration, venue: bar_venue }

    let(:date) { Date.current.tomorrow.strftime('%d/%m/%Y') }
    let(:duration) { 60 }
    let(:sport_name) { 'tennis' }

    subject { get :venues, date: date, sport_name: sport_name, duration: duration, format: :json }

    it 'has correct response code' do
      expect(response).to be_success
    end

    describe 'venues' do
      let(:venue_ids) { parsed_body[:response].map { |response| response[:venue][:id] } }
      it 'returns correct venues' do
        expect(venue_ids).to match_array [foo_venue.id, bar_venue.id]
      end
    end

    describe 'prepopulated' do
      let!(:foo_pre_venue) { create :venue, :prepopulated }
      let!(:bar_pre_venue) { create :venue, :prepopulated }
      let(:venue_ids) { parsed_body[:prepopulated].map { |response| response[:id] } }
      it 'returns correct venues' do
        expect(venue_ids).to match_array [foo_pre_venue.id, bar_pre_venue.id]
      end
    end

    describe 'metadata' do
      let(:metadata_duration) { parsed_body[:metadata][:duration] }
      it 'has correct duration' do
        expect(metadata_duration).to eq 60
      end
    end

    describe 'courts' do
      let(:court_ids) { parsed_body[:all_courts].map { |court| court[:id] } }
      it 'has correct courts' do
        expect(court_ids).to match_array [foo_court_1.id, bar_court_1.id]
      end
    end

    describe 'nested courts with payload' do
      let(:sport_name) { 'badminton' }
      let(:first_response_item) { parsed_body[:response].first }
      let(:parsed_venue) { first_response_item[:venue] }
      let(:parsed_courts) { first_response_item[:courts] }
      let(:parsed_court_ids) { parsed_courts.map { |court| court[:id] }}

      it 'has link to the original court' do
        expect(parsed_court_ids).to eq [foo_court_2.id]
      end

      describe 'available times and prices' do
        let(:sport_name) { 'tennis' }
        let(:available_times) { parsed_courts.first[:available_times] }
        let(:first_time) { available_times.first }
        let(:received_start_at) { DateTime.parse(first_time[:starts_at]) }
        let(:received_ends_at) { DateTime.parse(first_time[:ends_at]) }
        let(:received_price) { first_time[:price] }
        let(:received_duration) { first_time[:duration] }
        # these tests are important: assert that if we look for a 1 hour session
        # return 1 hour `available_times` options (not 30 minutes, not 2 hours)
        # (different from on city page search, where duration is specified by court duration policy)
        it_behaves_like 'a correct duration spitter for global search', 30, 5
        it_behaves_like 'a correct duration spitter for global search', 60, 10
        it_behaves_like 'a correct duration spitter for global search', 120, 20

        context 'when user with discount signed in' do
          let!(:current_user) { create :user, venues: [foo_venue] }
          let!(:discount) { create :discount, venue: foo_venue, users: [current_user] }
          # selects the discounted venue in response
          let(:first_response_item) { parsed_body[:response].find { |venue| venue.dig(:venue, :id) == discount.venue.id } }
          before { sign_in_for_api_with current_user }
          # we expect half the price
          it_behaves_like 'a correct duration spitter for global search', 60, 5
          it_behaves_like 'a correct duration spitter for global search', 120, 10
        end
      end
    end
  end

  describe 'GET #filter_by_name' do
    subject { get :filter_by_name, format: :json, name: name }
    let!(:venue_1) { create :venue, :searchable, :with_courts, venue_name: 'Norman', city: 'Vanncouver' }
    let!(:venue_2) { create :venue, :searchable, :with_courts, venue_name: 'Danny', city: 'Moskva' }

    let(:response_venues_ids) { parsed_body[:venues].map { |venue| venue[:id] }.sort }

    context 'when searching by venue name' do
      let(:name) { 'ANN' }
      it 'returns correct results' do
        expect(response_venues_ids).to eq [venue_1.id, venue_2.id]
        expect(response).to be_success
      end
    end

    context 'when searching by city name' do
      let(:name) { 'KVA' }
      it 'returns correct results' do
        expect(response_venues_ids).to eq [venue_2.id]
        expect(response).to be_success
      end
    end
  end
end
