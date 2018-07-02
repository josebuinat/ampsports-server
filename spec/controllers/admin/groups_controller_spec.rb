require "rails_helper"

describe Admin::GroupsController, type: :controller do
  render_views
  let!(:admin) { create :admin, :with_company }
  let!(:company) { admin.company }

  before { sign_in_for_api_with admin }

  describe "#index" do
    subject { get :index, params }

    let!(:venue) { create :venue, company: company }
    let!(:other_venue) { create :venue, company: company }
    let!(:coach) { create :coach, company: company }
    let!(:user) { create :user, venues: [venue] }
    let!(:user_group) { create :group, owner: user, venue: venue }
    let!(:admin_group) { create :group, venue: venue, owner: admin }
    let!(:coach_group) { create :group, venue: other_venue, coaches: [coach] }
    let!(:member_group) { create :group, venue: other_venue }
    let!(:member) { create :group_member, group: member_group, user: user }

    let(:group_ids) { json['groups'].map { |x| x['id'] } }

    let(:params) { {} }

    it 'returns groups' do
      is_expected.to be_success
      expect(group_ids).to match_array [user_group.id, admin_group.id, coach_group.id, member_group.id]
    end

    context 'with search by venue' do
      let(:params) { { venue_id: venue.id } }

      it 'returns venue groups' do
        is_expected.to be_success
        expect(group_ids).to match_array [user_group.id, admin_group.id]
      end
    end

    context 'with search by coach' do
      let(:params) { { coach_id: coach.id } }

      it 'returns coach groups' do
        is_expected.to be_success
        expect(group_ids).to match_array [coach_group.id]
      end
    end

    context 'with search by user' do
      let(:params) { { user_id: user.id } }

      it 'returns user owned or participated groups' do
        is_expected.to be_success
        expect(group_ids).to match_array [user_group.id, member_group.id]
      end
    end

    context 'with search by name' do
      let(:params) { { search: admin_group.name } }

      it 'returns searched groups' do
        is_expected.to be_success
        expect(group_ids).to match_array [admin_group.id]
      end
    end

    context 'when sorted on name' do
      let(:params) { { sort_on: 'name desc' } }

      it 'returns sorted groups' do
        is_expected.to be_success
        expect(group_ids).to eq [
          user_group, admin_group, coach_group, member_group
        ].sort_by(&:name).reverse.map(&:id)
      end
    end
  end
end
