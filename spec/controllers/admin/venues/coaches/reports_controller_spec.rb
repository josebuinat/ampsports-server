require 'rails_helper'

describe Admin::Venues::Coaches::ReportsController, type: :controller do
  render_views

  let!(:company) { create :company }
  let!(:venue) { create :venue, :with_courts, company: company }
  let!(:coach) { create :coach, :available, company: company, for_court: court1 }
  let(:court1) { venue.courts.first }
  let(:court2) { venue.courts.second }

  before { sign_in_for_api_with coach }

  describe '#index' do
    subject{ get :index, venue_id: venue.id, coach_id: coach.id, **params }

    let(:start_time) { in_venue_tz { Time.current.advance(days: 1).at_noon } }

    context 'for salary' do
      let(:params) do
        {
          sport: 'tennis',
          start_date: start_time.to_s(:date),
          end_date: start_time.advance(days: 3).to_s(:date)
        }
      end

      let!(:reservation1) {
        create :reservation, court: court1, coaches: [coach], start_time: start_time
      }
      let!(:reservation2) {
        create :reservation, court: court1, coaches: [coach], start_time: start_time.advance(days: 3)
      }
      let!(:reservation_outside_dates_search) {
        create :reservation, court: court2, coaches: [coach], start_time: start_time.advance(days: 4)
      }
      let!(:unrelated_reservation) {
        create :reservation, court: court1, start_time: start_time.advance(days: 1)
      }
      let(:reservation_ids) { json.dig('coach_reports', 'reservations').map { |x| x['id'] } }
      let(:court_ids) { json.dig('coach_reports', 'courts').map { |x| x['id'] } }

      it 'returns reservations and courts' do
        is_expected.to be_success

        expect(reservation_ids).to match_array [reservation1.id, reservation2.id]
        expect(court_ids).to match_array [court1.id]
      end
    end
  end

  describe '#download' do
    subject{ get :download, venue_id: venue.id, coach_id: coach.id, **params }

    let(:start_time) { in_venue_tz { Time.current.advance(days: 1).at_noon } }

    let(:params) do
      {
        sport: 'tennis',
        start_date: start_time.to_s(:date),
        end_date: start_time.advance(days: 3).to_s(:date)
      }
    end

    let!(:reservation) { create :reservation, court: court1, coaches: [coach], start_time: start_time }

    it 'returns report file' do
      is_expected.to be_success
      expect(response.header['Content-Type']).to include 'application/xlsx'
      expect(response.body).not_to eq '' # body should not be empty
      # can't use be_present bcause of 'invalid byte sequence in UTF-8'
    end
  end
end

