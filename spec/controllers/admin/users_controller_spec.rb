require 'rails_helper'

describe Admin::UsersController, type: :controller do
  render_views

  let!(:company) { create :company }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }
  let(:body) { JSON.parse response.body }

  # cannot connect user to company without venue
  let!(:venue) { create :venue, :searchable, company: company }

  describe 'GET #index' do
    subject { get :index, format: :json, **params }

    let!(:user_in_company_1) { create :user, first_name: 'Banana', venues: [venue] }
    let!(:user_in_company_2) { create :user, first_name: 'Apple', venues: [venue] }
    let!(:user_outside_company) { create :user, first_name: 'Apple' }

    let(:user_ids) { body['users'].map { |x| x['id'] } }

    context 'without search' do
      let(:params) { { search: nil } }
      it 'works' do
        is_expected.to be_success
        expect(user_ids).to match_array [ user_in_company_1.id, user_in_company_2.id ]
      end
    end

    context 'when searching' do
      let(:params) { { search: 'appl' } }
      it 'works' do
        is_expected.to be_success
        expect(user_ids).to eq [user_in_company_2.id]
      end
    end

    context 'when with_outstanding_balance param sent' do
      let!(:user_with_balance) { create :user, venues: [venue] }
      let!(:unpaid_game_pass) { create :game_pass, venue: venue, user: user_with_balance }
      let(:params) { { with_outstanding_balance: true } }

      it 'returns only users with outstanding balance' do
        is_expected.to be_success
        expect(user_ids).to eq [user_with_balance.id]
      end

      context 'when user_type saved_users param sent' do
        let!(:saved_user_with_balance) { create :user, venues: [venue] }
        let!(:unpaid_game_pass) { create :game_pass, venue: venue, user: user_with_balance }
        let(:params) { { with_outstanding_balance: true, user_type: 'saved_users' } }

        before(:each) do
          company.update(saved_invoice_users: [saved_user_with_balance])
        end

        it 'returns only saved users with outstanding balance' do
          is_expected.to be_success
          expect(user_ids).to eq [saved_user_with_balance.id]
        end
      end

      describe 'when user_type membership_users param sent' do
        let(:params) { { with_outstanding_balance: true, user_type: 'membership_users' } }
        let!(:court) { create :court, :with_prices, venue: venue }
        let(:user1) { create :user, venues: [venue] }
        let(:user2) { create :user, venues: [venue] }
        let(:group) { create :group, venue: venue, owner: user2 }
        let!(:user_membership) { create :membership, :with_reservations, venue: venue, user: user1 }
        let!(:group_membership) { create :membership, :with_reservations, venue: venue, user: group,
                                                      start_time: user_membership.start_time.advance(days: 1)}

        it 'returns only users with balance for requested custom biller' do
          is_expected.to be_success
          expect(user_ids).to match_array [user1.id, user2.id]
        end
      end

      context 'with custom_biller_id' do
        let(:params) { { with_outstanding_balance: true, custom_biller_id: custom_biller.id } }
        let(:group_with_biller) { create :group, :with_custom_biller, venue: venue }
        let(:court) { create :court, :with_prices, venue: venue }
        let(:user1) { create :user, venues: [venue] }
        let(:user2) { create :user, venues: [venue] }
        let(:user3) { create :user, venues: [venue] }
        let!(:reservation_with_biller) { create :reservation, :paid, user: group_with_biller, court: court }
        let!(:reservation_without_biller) { create :group_reservation, :paid, court: court,
                                              start_time: reservation_with_biller.start_time.advance(hours: 2) }
        let(:custom_biller) { group_with_biller.custom_biller }
        let!(:participation1) { create :participation, user: user1, reservation: reservation_with_biller }
        let!(:participation2) { create :participation, user: user2, reservation: reservation_with_biller }
        let!(:other_participation) { create :participation, user: user3, reservation: reservation_without_biller }

        it 'returns only users with balance for requested custom biller' do
          is_expected.to be_success
          expect(user_ids).to match_array [participation1.user_id, participation2.user_id]
        end
      end
    end
  end

  describe '#show' do
    subject { get :show, format: :json, id: user.id }
    let!(:user) { create :user, venues: [venue] }
    it { is_expected.to be_success }
  end

  describe '#create' do
    subject { post :create, format: :json, user: params }

    context 'with valid params' do
      let(:params) { { first_name: 'hey', last_name: 'ho', email: 'let@us.go' }}
      it 'creates a user' do
        expect { subject }.to change { company.users.count }.by(1)
        is_expected.to be_created
      end
    end

    context 'with invalid params' do
      let(:params) { { email: 'hey not an email here' }}
      it 'does not work' do
        expect { subject }.not_to change { company.users.reload.count }
        is_expected.to be_unprocessable
      end
    end

    context 'with email of existing user' do
      let!(:user) { create :user, venues: [venue] }
      let(:params) { { email: user.email }}

      it 'does not create new user' do
        expect { subject }.not_to change { company.users.reload.count }
        is_expected.to be_created
      end
    end
  end

  describe '#update' do
    subject { patch :update, format: :json, id: user.id, user: params }
    let!(:user) { create :user, :unconfirmed, venues: [venue] }
    context 'with valid params' do
      let(:params) { { first_name: 'new_name' } }
      it 'works' do
        expect { subject }.to change { user.reload.first_name }.to('new_name')
        is_expected.to be_success
      end
    end

    context 'with invalid params' do
      let(:params) { { email: 'this is not a email' } }
      it 'does not work' do
        expect { subject }.not_to change { user.reload.email }
        is_expected.to be_unprocessable
      end
    end

    context 'with email of existing user' do
      let!(:existing_user) { create :user, venues: [venue] }
      let(:params) { { email: existing_user.email }}

      it 'deletes incorrect user' do
        expect { subject }.to change { company.users.reload.count }.by(-1)
        is_expected.to be_success
      end

      context 'incorrect user with many companies' do
        let!(:other_company_venue) { create :venue, users: [user] }

        it 'does not delete incorrect user' do
          expect { subject }.not_to change { company.users.reload.count }
          is_expected.to be_success
        end
      end
    end
  end

  describe '#destroy' do
    subject { delete :destroy, format: :json, id: user.id }
    let!(:user) { create :user, :unconfirmed, venues: [venue] }

    it 'works' do
      expect { subject }.to change { company.users.count }.by(-1)
      is_expected.to be_success
    end

    context 'when user has upcoming reservations' do
      let!(:reservation) { create :reservation, user: user }

      it 'does not work' do
        expect { subject }.not_to change { User.count }
        is_expected.to be_unprocessable
      end
    end
  end
end
