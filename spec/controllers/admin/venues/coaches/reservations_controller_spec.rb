require 'rails_helper'

describe Admin::Venues::Coaches::ReservationsController, type: :controller do
  render_views

  let!(:company) { create :company }
  let!(:venue) { create :venue, :with_courts, company: company }
  let!(:coach) { create :coach, :available, company: company, for_court: court1, level: :manager }
  let(:court1) { venue.courts.first }
  let(:court2) { venue.courts.second }

  before { sign_in_for_api_with coach }

  describe '#index' do
    subject{ get :index, venue_id: venue.id, coach_id: coach.id, **params }

    let(:start_time) { in_venue_tz { Time.current.advance(days: 1).at_noon } }

    let(:params) do
      {
        sport: 'tennis',
        start: start_time.to_s(:date),
        end: start_time.advance(days: 7).to_s(:date)
      }
    end

    context 'with reservations' do
      let!(:reservation1) {
        create :reservation, court: court1, coaches: [coach], start_time: start_time
      }
      let!(:reservation2) {
        create :reservation, court: court1, coaches: [coach], start_time: start_time.advance(days: 7)
      }
      let!(:reservation_outside_dates_search) {
        create :reservation, court: court2, coaches: [coach], start_time: start_time.advance(days: 8)
      }
      let!(:unrelated_reservation) {
        create :reservation, court: court1, start_time: start_time.advance(days: 1)
      }
      let(:reservation_ids) { json['reservations'].map { |x| x['id'] } }
      let(:court_ids) { json['courts'].map { |x| x['id'] } }

      it 'returns reservations and courts' do
        is_expected.to be_success

        expect(reservation_ids).to match_array [reservation1.id, reservation2.id]
        expect(court_ids).to match_array [court1.id]
      end
    end
  end

  describe '#unavailable_slots' do
    subject do
      get :unavailable_slots, venue_id: venue.id, coach_id: coach.id, format: :json,
        start: start_time.to_s(:date), end: (start_time + 7.days).to_s(:date)
    end

    let(:start_time) { in_venue_tz { Time.current.advance(days: 1).at_noon } }

    let!(:unrelated_reservation1) {
      create :reservation, court: court1, start_time: start_time }
    let!(:unrelated_reservation2) {
      create :reservation, court: court2, start_time: start_time.advance(minutes: 30) }

    it 'returns unavailable slot for the overlapping part' do
      is_expected.to be_success

      expect(json).to include({ 'start' => start_time.advance(minutes: 30),
        'end' => start_time.advance(minutes: 60) })
    end

  end
end
