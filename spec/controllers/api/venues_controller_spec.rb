require 'rails_helper'

shared_examples 'a correct duration spitter for on venue page search' do |duration_policy, duration_to_expect, price|
  let(:court_2_duration_policy) { duration_policy }
  let(:expected_start_at) { DateTime.parse(search_date).change(hour: 6, minute: 0, second: 0) }
  let(:expected_ends_at) { expected_start_at.advance(minutes: duration_to_expect) }
  it 'has available times' do
    # just many times, no matter how many
    # (it should be covered by #court.available_times)
    expect(available_times.size).to be > 15
    expect(received_start_at.to_s(:db)).to eq expected_start_at.to_s(:db)
    expect(received_ends_at.to_s(:db)).to eq expected_ends_at.to_s(:db)
    expect(received_price).to eq price
    expect(received_duration).to eq duration_to_expect
  end
end

describe API::VenuesController, type: :controller do
  render_views

  describe 'static actions' do
    before(:all) do
      @venue = FactoryGirl.create(:venue)
      @court = FactoryGirl.create(:court, venue: @venue)
    end

    after(:all) do
      @court.destroy
      @venue.destroy
    end

    it 'will return sports list' do
      get :sports, venue_id: @venue.id
      response_json = JSON.parse(response.body)
      expect(response_json[0]['label']).to eq('Tennis')
    end
  end

  describe '#index' do
    subject { get :index, format: :json, sport: sport_param, city: city_param, country: country_param }
    let(:sport_param) { nil }
    let(:city_param) { nil }
    let(:country_param) { nil }
    let(:response_venue_ids) { JSON.parse(response.body)['venues'].map { |x| x['id'] } }

    context 'with different cities' do
      let!(:venue_1) { create :venue, :searchable, :with_courts, city: 'Okko' }
      # do not search for a part of a city here
      let!(:venue_2) { create :venue, :searchable, :with_courts, city: 'Okkomadan' }
      let!(:venue_3) { create :venue, :searchable, :with_courts, city: 'Bishkek' }
      let(:city_param) { 'okko' }

      it 'returns correct venues' do
        is_expected.to be_success
        expect(response_venue_ids).to eq [venue_1.id]
      end
    end

    context 'with different countries' do
      let(:fin_company) { create :company, country: Country.find_country('FI') }
      let(:usa_company) { create :usa_company }
      let!(:venue_1) { create :venue, :searchable, :with_courts, company: fin_company }
      let!(:venue_2) { create :venue, :searchable, :with_courts, company: fin_company }
      let!(:venue_3) { create :venue, :searchable, :with_courts, company: usa_company }
      let(:country_param) { 'US' }

      it 'returns correct venues' do
        is_expected.to be_success
        expect(response_venue_ids).to eq [venue_3.id]
      end
    end
  end

  describe 'GET #courts' do
    let!(:venue) { create :venue, :searchable, courts: [court_1] }
    let(:court_1) { create :court, :with_prices,
                           sport_name: :tennis,
                           duration_policy: :any_duration
    }

    subject { get :courts, venue_id: venue.id, format: :json }
    let(:parsed_body) { JSON.parse(subject.body).with_indifferent_access }
    let(:court_ids) { parsed_body[:courts].map { |court| court[:court_id] } }

    it 'returns correct courts' do
      expect(court_ids).to eq [court_1.id]
    end
  end

  # assert mostly schema here + important test for correct durations
  describe 'GET #available_courts' do
    let(:venue) { create :venue, :searchable }
    let!(:court_1) { create :court, :with_prices,
                           venue: venue,
                           sport_name: :tennis,
                           duration_policy: :any_duration
    }
    let!(:court_2) { create :court, :with_prices,
                           venue: venue,
                           sport_name: :badminton,
                           duration_policy: court_2_duration_policy
    }

    let(:court_2_duration_policy) { :one_hour }

    let(:search_date) { Date.current.tomorrow.strftime('%d/%m/%Y') }
    let(:sport_name) { 'tennis' }

    subject { get :available_courts, date: search_date, sport_name: sport_name, venue_id: venue.id, format: :json }
    let(:parsed_body) { JSON.parse(subject.body).with_indifferent_access }

    describe 'venue' do
      let(:parsed_venue) { parsed_body[:venue] }
      it 'returns venue' do
        expect(parsed_venue).to be_present
        expect(parsed_venue[:id]).to eq venue.id
      end
    end

    describe 'all_courts' do
      let(:court_ids) { parsed_body[:all_courts].map { |court| court[:id] } }
      context 'when playing tennis' do
        it 'has correct courts' do
          expect(court_ids).to eq [court_1.id]
        end
      end

      context 'when playing badminton' do
        let(:sport_name) { 'badminton' }
        it 'has correct courts' do
          expect(court_ids).to eq [court_2.id]
        end
      end
    end

    describe 'courts with payload' do
      let(:sport_name) { 'badminton' }
      let(:parsed_courts) { parsed_body[:courts] }
      let(:parsed_court_ids) { parsed_courts.map { |court| court[:id] }}

      it 'has link to the original court' do
        expect(parsed_court_ids).to eq [court_2.id]
      end

      describe 'available times and prices' do
        let(:available_times) { parsed_courts.first[:available_times] }
        let(:first_time) { available_times.first }
        let(:received_start_at) { DateTime.parse(first_time[:starts_at]) }
        let(:received_ends_at) { DateTime.parse(first_time[:ends_at]) }
        let(:received_price) { first_time[:price] }
        let(:received_duration) { first_time[:duration] }
        # checks that it returns correct durations, based on courts duration (different from main search,
        # where duration is set in a query)
        it_behaves_like 'a correct duration spitter for on venue page search', :any_duration, 30, 5
        it_behaves_like 'a correct duration spitter for on venue page search', :one_hour, 60, 10
        it_behaves_like 'a correct duration spitter for on venue page search', :two_hour, 120, 20

        context 'edge case' do
          context 'daylight saving time' do
            let(:search_date) { '12/03/2017' } # DST start in Pacific Time Zone in 2017

            before do
              allow(Time).to receive(:current).and_return(Date.parse('11/03/2017').in_time_zone(venue.timezone))
            end

            it_behaves_like 'a correct duration spitter for on venue page search', :any_duration, 30, 5
            it_behaves_like 'a correct duration spitter for on venue page search', :one_hour, 60, 10
            it_behaves_like 'a correct duration spitter for on venue page search', :two_hour, 120, 20
          end
        end
      end
    end

    describe '#show' do
      let(:venue) { create :venue, :searchable, city: 'Okko' }
      let!(:court) { create :court, :with_prices,
                             venue: venue,
                             sport_name: :tennis,
                             duration_policy: :any_duration
      }
      subject { get :show, id: venue.id, format: :json }
      let(:parsed_body) { JSON.parse(subject.body) }

      expected = {
        "fri" => {"opening" => 0, "closing" => 86400},
        "mon" => {"opening" => 0, "closing" => 86400},
        "sat" => {"opening" => 0, "closing" => 86400},
        "sun" => {"opening" => 0, "closing" => 86400},
        "thu" => {"opening" => 0, "closing" => 86400},
        "tue" => {"opening" => 0, "closing" => 86400},
        "wed" => {"opening" => 0, "closing" => 86400},
      }
      it 'returns venue with correct business hours' do
        expect(parsed_body['business_hours']).to eq expected
      end
    end

    context 'with favourites' do
      before { sign_in_for_api_with(user) }
      let(:venue) { create :venue }
      let(:user) { create :user, :with_favourites }

      describe 'GET #favourites' do
        subject { get :favourites }

        it 'is successful' do
          expect(subject.status).to eq(200)
        end

        it 'returns favourites' do
          subject
          response_json = JSON.parse(response.body)
          expect(response_json['venues'].count).to eq(user.favourites.count)
        end
      end

      describe 'POST #make_favourite' do
        subject { post :make_favourite, venue_id: venue.id }

        it 'is successful' do
          expect(subject.status).to eq(200)
        end

        it 'adds venue to favourites' do
          expect { subject }.to change { user.favourites.count }.by(1)
        end
      end

      describe 'POST #unfavourite' do
        subject { post :unfavourite, venue_id: user.favourites.first.id }

        it 'is successful' do
          expect(subject.status).to eq(200)
        end

        it 'removes venue from favourites' do
          expect { subject }.to change { user.favourites.count }.by(-1)
        end
      end
    end
  end
end
