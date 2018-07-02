require "rails_helper"

describe Admin::Venues::Reservations::ParticipationsController, type: :controller do
  render_views
  let!(:admin) { create :admin, :with_company }
  let!(:company) { admin.company }
  let!(:venue) { create :venue, :with_users, :with_courts, user_count: 3, company: company }
  let!(:group) { create :group, venue: venue, owner: venue.users.first }
  let!(:reservation) { create :reservation, court: venue.courts.first, user: group }

  before { sign_in_for_api_with admin }

  describe 'GET #index' do
    subject{ get :index, venue_id: venue.id, reservation_id: reservation.id }

    let(:participation_ids) { json['participations'].map { |x| x['id'] } }

    let!(:participation1) { create :participation, user: venue.users.second, reservation: reservation }
    let!(:participation2) { create :participation, user: venue.users.third, reservation: reservation }
    let!(:other_venue_participation) { create :participation }

    it 'returns participations' do
      is_expected.to be_success
      expect(participation_ids).to match_array [participation1.id, participation2.id]
    end
  end

  describe 'GET #show' do
    subject{ get :show, venue_id: venue.id, reservation_id: reservation.id, id: participation.id }

    let!(:participation) { create :participation, user: venue.users.second, reservation: reservation }

    it 'returns participation JSON' do
      is_expected.to be_success

      expect(json['id']).to eq participation.id
      expect(json.dig('user', 'id')).to eq participation.user.id
    end
  end

  describe 'POST #create' do
    subject{ post :create, venue_id: venue.id, reservation_id: reservation.id, **params }

    let(:user) { venue.users.second }
    let(:user_id) { user.id }
    let(:params) do
      {
        participation: {
          user_id: user_id,
          price: 33.33
        }
      }
    end

    context 'with valid params' do
      it 'creates participation' do
        expect{ subject }.to change{ reservation.participations.count }.by(1)
        is_expected.to be_created

        new_participation = reservation.participations.last
        expect(new_participation.user).to eq user
        expect(new_participation.price).to eq 33.33
      end
    end

    context 'with invalid params' do
      let(:user_id) { nil }

      it 'does not create participation' do
        expect{ subject }.not_to change{ reservation.participations.count }
        is_expected.to be_unprocessable
      end
    end
  end

  describe 'DELETE #destroy_many' do
    subject{ delete :destroy_many, venue_id: venue.id, reservation_id: reservation.id, **params }

    let!(:participation1) { create :participation, user: venue.users.second, reservation: reservation }
    let!(:participation2) { create :participation, user: venue.users.third, reservation: reservation }
    let!(:other_participation) { create :participation, user: venue.users.first, reservation: reservation }

    let(:params) { { participation_ids: [participation1.id, participation2.id] } }

    it 'cancels participations' do
      expect{ subject }.to change{ reservation.participations.active.count }.by(-2)
                       .and change{ reservation.participations.cancelled.count }.by(2)

      is_expected.to be_success
    end
  end

  describe 'PATCH #mark_paid_many' do
    subject{ patch :mark_paid_many, venue_id: venue.id, reservation_id: reservation.id, **params }

    let!(:participation1) { create :participation, user: venue.users.second, reservation: reservation }
    let!(:participation2) { create :participation, user: venue.users.third, reservation: reservation }
    let!(:other_participation) { create :participation, user: venue.users.first, reservation: reservation }

    let(:params) { { participation_ids: [participation1.id, participation2.id] } }

    it 'marks participations as paid' do
      expect{ subject }.to change{ reservation.participations.invoiceable.count }.by(-2)

      is_expected.to be_success
    end
  end
end
