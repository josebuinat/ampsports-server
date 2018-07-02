require "rails_helper"

describe Admin::Venues::Groups::MembersController, type: :controller do
  render_views
  let!(:admin) { create :admin, :with_company }
  let!(:company) { admin.company }
  let!(:venue) { create :venue, :with_users, user_count: 2, company: company }
  let!(:group) { create :group, venue: venue, owner: venue.users.first }

  before { sign_in_for_api_with admin }

  describe '#index' do
    subject { get :index, venue_id: venue.id, group_id: group.id }

    let!(:member1) { create :group_member, group: group }
    let!(:member2) { create :group_member, group: group }

    let(:member_ids) { json['members'].map { |x| x['id'] } }

    it 'returns group members JSON' do
      is_expected.to be_success
      expect(member_ids).to eq [member1.id, member2.id]
    end
  end

  describe '#show' do
    subject { get :show, venue_id: venue.id, group_id: group.id, id: member.id }

    let!(:member) { create :group_member, group: group }

    it 'returns group member' do
      is_expected.to be_success
      expect(json.dig('user', 'id')).to eq member.user_id
    end
  end

  describe '#create' do
    subject { post :create, venue_id: venue.id, group_id: group.id, **params }

    let(:user2) { venue.users.second }
    let(:params) { { member: { user_id: user2.id } } }

    it 'creates group member' do
      expect{ subject }.to change{ group.reload.members.count }.by(1)

      is_expected.to be_created
    end
  end

  describe '#destroy' do
    subject { delete :destroy, venue_id: venue.id, group_id: group.id, id: member.id }

    let!(:member) { create :group_member, group: group }

    it 'deletes group member' do
      expect{ subject }.to change{ group.reload.members.count }.by(-1)

      is_expected.to be_success
      expect(json).to eq [member.id]
    end
  end

  describe '#destroy_many' do
    subject{ delete :destroy_many, venue_id: venue.id, group_id: group.id, **params }

    let!(:member1) { create :group_member, group: group }
    let!(:member2) { create :group_member, group: group }
    let!(:other_member) { create :group_member, group: group }

    let(:params) { { member_ids: [member1.id, member2.id] } }

    it 'deletes group members' do
      expect{ subject }.to change{ group.members.count }.by(-2)

      is_expected.to be_success
      expect(json).to match_array [member1.id, member2.id]
    end
  end
end
