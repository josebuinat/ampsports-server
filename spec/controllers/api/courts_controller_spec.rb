require 'rails_helper'

describe API::CourtsController, type: :controller do
  render_views

  describe 'courts #reservations' do
    let!(:venue) { create :venue, :searchable, courts: [court] }
    let(:court) { create :court, :with_prices, sport_name: :tennis, duration_policy: :any_duration }
    let(:reservation) { create :reservation, court: court }
    let(:parsed_body) { JSON.parse(response.body).with_indifferent_access }
    let(:reservation_ids) { parsed_body[:reservations].map { |reservation| reservation[:id] } }
    let(:date) { reservation.start_time.to_date }

    it 'return correct reservations with court_id' do
      get :reservations, court_id: court.id, date: date
      expect(reservation_ids).to eq [reservation.id]
    end

    it 'return correct reservations without court_id' do
      get :reservations, venue_id: venue.id, date: date
      expect(reservation_ids).to eq [reservation.id]
    end

    context 'edge cases for start time (24h range)' do
      let(:reservation) { create :reservation, court: court, start_time: start_time }
      before { get :reservations, court_id: court.id, date: date }

      context 'when reservation start time is 06:00' do
        let(:start_time) { in_venue_tz { Time.current.advance(weeks: 2).beginning_of_week.change(hour: 6) } }
        it 'return correct reservations' do
          expect(reservation_ids).to eq [reservation.id]
        end
      end

      context 'when reservation start time is 22:00' do
        let(:start_time) { in_venue_tz { Time.current.advance(weeks: 2).beginning_of_week.change(hour: 21) } }
        it 'return correct reservations' do
          expect(reservation_ids).to eq [reservation.id]
        end
      end
    end

    context 'when company uses usd' do
      let(:venue) { create :usd_venue, :searchable}
      let(:court) { create :court, :with_prices,
                                   venue: venue,
                                   sport_name: :tennis,
                                   duration_policy: :any_duration
      }

      before do
        get :reservations, court_id: court.id, date: date
      end

      it 'returns prices in dollars' do
        prices = parsed_body[:reservations].map { |reservation| reservation[:price] }
        expect(prices).to eql ['$20.00']
      end
    end
  end
end
