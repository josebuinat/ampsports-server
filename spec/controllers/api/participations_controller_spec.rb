require 'rails_helper'

describe API::ParticipationsController, type: :controller do
  render_views
  let!(:venue) { create :venue, :with_courts, court_count: 1 }
  let!(:user) { create :user, venues: [venue] }
  let!(:group) { create :group, venue: venue }
  let!(:reservation) { create :reservation, user: group, court: venue.courts.first }
  let!(:participation) { create :participation, user: user, reservation: reservation }

  before(:each) do
    sign_in_for_api_with(user)
  end

  describe "GET #index" do
    subject { get :index, user_id: user.id }

    let!(:other_user_participation) { create :participation, user: group.owner }

    it 'returns participations JSON' do
      is_expected.to be_success

      expect(json['participations'].map { |x| x['id'] }).to eq [participation.id]
    end
  end

  describe "GET #show" do
    subject { get :show, user_id: user.id, id: participation.id }

    it 'returns participation JSON' do
      is_expected.to be_success

      expect(json['id']).to eq participation.id
    end

    it 'returns participation reservation JSON' do
      is_expected.to be_success

      expect(json['reservation']['id']).to eq reservation.id
    end

    it 'returns participation group JSON' do
      is_expected.to be_success

      expect(json['group']['id']).to eq group.id
    end
  end

  describe "PATCH #cancel" do
    subject { patch :cancel, id: participation.id }

    context 'with owner request' do
      let(:requester) { user }

      it 'cancels participation' do
        is_expected.to be_success

        expect(Participation.unscoped.find(participation.id).cancelled).to be_truthy
      end
    end

    context 'with other user request' do
      it 'does not cancel participation' do
        sign_in_for_api_with(group.owner)
        is_expected.to be_not_found

        expect(Participation.unscoped.find(participation.id).cancelled).to be_falsey
      end
    end
  end
end
