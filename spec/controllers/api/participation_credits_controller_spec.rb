require 'rails_helper'

describe API::ParticipationCreditsController, type: :controller do
  render_views
  let!(:venue) { create :venue, :with_courts, court_count: 1 }
  let!(:user) { create :user, venues: [venue] }
  let!(:group) { create :group, venue: venue }
  let!(:participation_credit) {
    create :participation_credit, company: venue.company,
                                  user: user,
                                  group_classification: group.classification
  }


  before(:each) do
    sign_in_for_api_with(user)
  end

  describe "GET #index" do
    subject { get :index, user_id: user.id }

    let!(:other_user_participation_credit) { create :participation_credit, company: venue.company }

    it 'returns participation_credits JSON' do
      is_expected.to be_success

      expect(json['participation_credits'].map { |x| x['id'] }).to eq [participation_credit.id]
    end
  end

  describe "GET #show" do
    subject { get :show, user_id: user.id, id: participation_credit.id }

    it 'returns participation_credit JSON' do
      is_expected.to be_success

      expect(json['id']).to eq participation_credit.id
    end

    context 'with applicable reservations' do
      let!(:reservation) { create :reservation, user: group, court: venue.courts.first }
      let!(:other_classification_group) { create :group, venue: venue }
      let!(:other_classification_reservation) { create :reservation, user: other_classification_group }

      it 'returns applicable reservations JSON' do
        is_expected.to be_success

        reservations_ids = json['applicable_reservations'].map { |x| x['id'] }

        expect(reservations_ids).to eq [reservation.id]
      end

      it 'returns applicable reservations group JSON' do
        is_expected.to be_success

        group_names = json['applicable_reservations'].map { |x| x['group']['name'] }

        expect(group_names).to eq [group.name]
      end
    end
  end

  describe "PATCH #use" do
    subject { patch :use, id: participation_credit.id,
                          reservation_id: reservation.id }

    let!(:reservation) { create :reservation, user: group, court: venue.courts.first }

    context 'with owner request' do
      it 'uses participation_credit' do
        expect{ subject }.to change{ ParticipationCredit.count }

        is_expected.to be_success
      end

      it 'creates paid participation for user and reservation' do
        expect{ subject }.to change{ Participation.count }

        participation = Participation.last

        expect(participation.user).to eq user
        expect(participation.reservation).to eq reservation
        expect(participation.is_paid).to be_truthy
      end

      context 'when not applicable reservation' do
        before(:each) do
          user.update(skill_level: group.skill_levels.first - 0.5)
        end

        it 'does not use participation_credit' do
          expect{ subject }.not_to change{ ParticipationCredit.count }

          is_expected.to be_unprocessable
        end
      end
    end

    context 'with other user request' do
      it 'does not use participation_credit' do
        sign_in_for_api_with(create(:user, venues: [venue]))
        expect{ subject }.not_to change{ ParticipationCredit.count }

        is_expected.to be_not_found
      end
    end
  end
end
