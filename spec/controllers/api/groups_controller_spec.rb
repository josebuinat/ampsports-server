require 'rails_helper'

describe API::GroupsController, type: :controller do
  render_views
  let!(:venue) { create :venue }
  let!(:user) { create :user, venues: [venue] }
  let!(:owned_group) { create :group, owner: user, venue: venue }

  before(:each) do
    sign_in_for_api_with(user)
  end

  describe "GET #index" do
    subject { get :index }

    let!(:other_user_group) { create :group, venue: venue }

    it 'returns owned groups JSON' do
      is_expected.to be_success

      expect(json['groups'].map { |group| group['id'] }).to eq [owned_group.id]
    end
  end

  describe "GET #show" do
    subject { get :show, id: owned_group.id }

    let!(:group_member) { create :group_member, group: owned_group }
    let!(:reservation) { create :reservation, user: owned_group }

    it 'returns group JSON' do
      is_expected.to be_success

      expect(json['id']).to eq owned_group.id
    end

    it 'returns group members JSON' do
      is_expected.to be_success

      expect(json['members'].map { |member| member['id'] }).to eq [group_member.user_id]
    end

    it 'returns group reservations JSON' do
      is_expected.to be_success

      expect(json['reservations'].map { |reservation| reservation['id'] }).to eq [reservation.id]
    end
  end
end
