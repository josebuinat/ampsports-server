require 'rails_helper'

describe Admin::Venues::Emails::Lists::UsersController, type: :controller do
  render_views

  let!(:company) { create :company }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }
  let!(:venue) { create :venue, :with_users, user_count: 2, company: company }
  let!(:user) { venue.users.first }
  let!(:other_user) { venue.users.second }
  let!(:list) { create :email_list, venue: venue, users: [user] }

  describe '#index' do
    subject { get :index, format: :json, venue_id: venue.id, list_id: list.id }

    let!(:other_venue_user) { create :user }

    let(:body) { JSON.parse response.body }
    let(:user_ids) { body['users'].map { |x| x['id'] } }

    it 'returns users JSON' do
      is_expected.to be_success
      expect(user_ids).to eq [user.id]
    end
  end

  describe '#not_listed' do
    subject { get :not_listed, format: :json, venue_id: venue.id, list_id: list.id }

    let!(:other_venue_user) { create :user }

    let(:body) { JSON.parse response.body }
    let(:user_ids) { body['users'].map { |x| x['id'] } }

    it 'returns not listed users JSON' do
      is_expected.to be_success
      expect(user_ids).to eq [other_user.id]
    end
  end

  describe '#add_many' do
    subject { post :add_many, format: :json, venue_id: venue.id, list_id: list.id, user_ids: [other_user.id] }

    let(:body) { JSON.parse response.body }
    let(:user_ids) { body['users'].map { |x| x['id'] } }

    it 'adds user to list' do
      is_expected.to be_success
      expect(user_ids).to match_array [user.id, other_user.id]
      expect(list.reload.users).to match_array [user, other_user]
    end

    context 'when add_all param was sent' do
      subject { post :add_many, format: :json, venue_id: venue.id, list_id: list.id, add_all: 1 }

      it 'adds all users to list' do
        is_expected.to be_success
        expect(user_ids).to match_array [user.id, other_user.id]
        expect(list.reload.users).to match_array [user, other_user]
      end
    end
  end

  describe '#remove_many' do
    subject { delete :remove_many, format: :json, venue_id: venue.id, list_id: list.id, user_ids: [user.id] }

    let(:body) { JSON.parse response.body }
    let(:user_ids) { body['users'].map { |x| x['id'] } }

    it 'removes user from list' do
      expect { subject }.to change { list.reload.users.count }.to(0)
      is_expected.to be_success
      expect(user_ids).to eq []
    end

    it 'does not remove user himself' do
      expect { subject }.not_to change { User.count }
      is_expected.to be_success
    end
  end
end
