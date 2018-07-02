require "rails_helper"

describe Admin::Venues::Groups::ReservationsController, type: :controller do
  render_views
  let!(:admin) { create :admin, :with_company }
  let!(:company) { admin.company }
  let!(:venue) { create :venue, :with_users, :with_courts, user_count: 1, company: company }
  let(:court) { venue.courts.first }
  let!(:group) { create :group, venue: venue, owner: venue.users.first }
  let!(:other_group) { create :group, venue: venue, owner: venue.users.first }

  before { sign_in_for_api_with admin }

  describe '#index' do
    subject { get :index, venue_id: venue.id, group_id: group.id }

    let!(:reservation1) { create :reservation, user: group, court: court }
    let!(:reservation2) {
      create :reservation, user: group,
                           court: court,
                           start_time: reservation1.start_time + 1.days }
    let!(:other_group_reservation) {
      create :reservation, user: other_group,
                           court: court,
                           start_time: reservation2.start_time + 1.days }

    let(:reservation_ids) { json['reservations'].map { |x| x['id'] } }

    it 'returns reservations JSON' do
      is_expected.to be_success
      expect(reservation_ids).to eq [reservation1.id, reservation2.id]
    end
  end
end
