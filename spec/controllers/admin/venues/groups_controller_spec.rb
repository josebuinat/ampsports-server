require "rails_helper"

describe Admin::Venues::GroupsController, type: :controller do
  render_views
  let!(:admin) { create :admin, :with_company }
  let!(:company) { admin.company }
  let!(:venue) { create :venue, :with_users, user_count: 2, company: company }
  let(:date) { Date.current }
  let(:seasons) {
    [
      { start_date: date.to_s(:date),
        end_date: date.advance(days: 10).to_s(:date),
        current: true },
      { start_date: date.advance(days: 11).to_s(:date),
        end_date: date.advance(days: 20).to_s(:date),
        participation_price: 1452.66 }
    ]
  }

  before { sign_in_for_api_with admin }

  describe "#index" do
    subject { get :index, venue_id: venue.id }

    let!(:coach) { create :coach, company: company }
    let!(:group1) { create :group, owner: venue.users.first, venue: venue,
                                   coaches: [coach], priced_duration: :season }
    let!(:season) { create :group_season, group: group1, current: true }
    let!(:group2) { create :group, venue: venue, owner: admin }
    let!(:other_venue_group) { create :group }

    let(:group_ids) { json['groups'].map { |x| x['id'] } }

    it 'returns JSON with error if venue not found' do
      venue.id = 'not existing'

      is_expected.to be_not_found
      expect(json['errors']).to include(I18n.t('api.record_not_found'))
    end

    it 'returns groups JSON' do
      is_expected.to be_success
      expect(group_ids).to eq [group1.id, group2.id]
    end

    it 'returns seasons data' do
      is_expected.to be_success

      seasons_data = json['groups'].first['seasons']
      expect(seasons_data).to be_a Array
      expect(seasons_data.first).to include({'start_date' => season.start_date.to_s,
                                             'end_date' => season.end_date.to_s})
    end

    context 'with user owner' do
      it 'returns owner_id and user data' do
        is_expected.to be_success

        group_data = json['groups'].first
        expect(group_data).to include('owner_id' => group1.owner_id)
        expect(group_data.dig('owner')).to include('id' => group1.owner_id)
      end
    end

    context 'with admin owner' do
      it 'returns nil owner_id and admin data' do
        is_expected.to be_success

        group_data = json['groups'].second
        expect(group_data).to include('owner_id' => nil)
        expect(group_data.dig('owner')).to include('id' => admin.id)
      end
    end

    context 'when sorted on name' do
      subject{ get :index, venue_id: venue.id, sort_on: 'name desc' }

      it 'returns sorted groups' do
        is_expected.to be_success
        expect(group_ids).to eq [group2.id, group1.id]
      end
    end
  end

  describe "#show" do
    subject { get :show, venue_id: venue.id, id: group.id }

    let!(:coach) { create :coach, company: company }
    let!(:group) { create :group, venue: venue, owner: venue.users.first, coaches: [coach],
                                  priced_duration: :season }
    let!(:season) { create :group_season, group: group, current: true }

    it 'returns JSON with error if group not found' do
      group.id = 'not existing'

      is_expected.to be_not_found
      expect(json['errors']).to include(I18n.t('api.record_not_found'))
    end

    it 'works' do
      is_expected.to be_success

      expect(json).to include('id' => group.id, 'owner_id' => group.owner_id)
    end
  end

  describe "#create" do
    subject { post :create, params }

    let(:owner_id) { venue.users.first.id }
    let!(:classification1) { create :group_classification, venue: venue }
    let!(:classification2) { create :group_classification, venue: venue }
    let!(:coach) { create :coach, company: company }
    let!(:params) {{
      venue_id: venue.id,
      group: {
        owner_id: owner_id,
        seasons: seasons,
        classification_id: classification1.id,
        coach_ids: [coach.id],
        name: 'group name',
        description: 'description',
        max_participants: '8',
        participation_price: '17.6',
        priced_duration: 'season',
        cancellation_policy: 'participation',
        skill_levels: ['4','5','6'],
      }
    }}
    let(:new_group) { venue.groups.last }

    context 'with user owner' do
      it 'creates group with user owner' do
        expect{ subject }.to change(Group, :count)

        is_expected.to be_created
        expect(new_group.owner).to eq venue.users.first
        expect(json['id']).to eq new_group.id
      end

      it 'saves seasons to group' do
        is_expected.to be_created

        expect(new_group.seasons.count).to eq 2
        expect(new_group.seasons.first.start_date).to eq date
        expect(new_group.seasons.first.end_date).to eq(date + 10.days)
        expect(new_group.seasons.first.get_participation_price).to eq new_group.participation_price
        expect(new_group.seasons.last.get_participation_price).to eq 1452.66
      end

      it 'saves coaches to group' do
        is_expected.to be_created

        expect(new_group.coaches).to include coach
      end
    end

    context 'with admin owner' do
      let(:owner_id) { nil }

      it 'creates group with admin owner' do
        expect{ subject }.to change(Group, :count).by(1)

        is_expected.to be_created
        expect(new_group.owner).to eq admin
        expect(json['id']).to eq new_group.id
      end
    end

    context 'with invalid data' do
      before(:each) do
        params[:group][:name] = nil
      end

      it 'returns JSON with errors messages' do
        is_expected.to be_unprocessable

        expect(json['errors']).to include('name' => ["can't be blank"])
      end
    end
  end

  describe "#update" do
    subject { put :update, params }

    let!(:group) { create :group, venue: venue, priced_duration: :season }
    let!(:season) { create :group_season, group: group,
                              start_date: date.advance(days: 21).to_s(:date),
                              end_date: date.advance(days: 30).to_s(:date),
                              current: true }

    let!(:classification1) { create :group_classification, venue: venue }
    let!(:classification2) { create :group_classification, venue: venue }
    let!(:coach) { create :coach, company: company }
    let(:owner_id) { venue.users.first.id }

    let!(:params) {{
      id: group.id,
      venue_id: venue.id,
      group: {
        owner_id: owner_id,
        seasons: [season_params],
        classification_id: classification1.id,
        coach_id: coach.id,
        name: 'group name',
        description: 'description',
        max_participants: '8',
        participation_price: '17.6',
        priced_duration: 'season',
        cancellation_policy: 'participation',
        skill_levels: ['4','5','6'],
      }
    }}
    let(:season_params) { {
      id: season_id,
      start_date: date.to_s(:date),
      end_date: date.advance(days: 10).to_s(:date),
      current: true,
      _destroy: delete_season
    } }
    let(:delete_season) { false }
    let(:season_id) { season.id }

    context 'with user owner' do
      let(:owner_id) { venue.users.first.id }

      it 'assigns group to user owner' do
        expect{ subject }.to change{ group.reload.owner }.to(venue.users.first)

        is_expected.to be_success
      end
    end

    context 'with admin owner' do
      let(:owner_id) { nil }

      it 'assigns group to admin owner' do
        expect{ subject }.to change{ group.reload.owner }.to(admin)

        is_expected.to be_success
      end
    end

    context 'when updating existing season' do
      it 'does not create duplicated season' do
        expect{ subject }.not_to change{ group.reload.seasons.count }
      end

      it 'updates season dates' do
        expect{ subject }.to change{ season.reload.start_date }.to(date)
                         .and change{ season.reload.end_date }.to(date.advance(days: 10))
      end
    end

    context 'when creating additional season' do
      let(:season_id) { nil }

      it 'creates season' do
        expect{ subject }.to change{ group.reload.seasons.count }.by(1)
        expect(group.seasons.count).to eq 2
      end
    end

    context 'when deleting existing season' do
      let(:delete_season) { true }

      it 'deletes season and shifts current to last' do
        create :group_season, group: group,
                              start_date: date.advance(days: 31).to_s(:date),
                              end_date: date.advance(days: 50).to_s(:date)

        expect{ subject }.to change{ group.reload.seasons.count }.by(-1)
                         .and change{ group.reload.seasons.last.current }.from(false).to(true)
      end
    end

    context 'with invalid data' do
      context 'with invalid group params' do
        it 'returns JSON with errors messages' do
          params[:group][:name] = nil

          is_expected.to be_unprocessable

          expect(json['errors']).to include('name' => ["can't be blank"])
        end
      end

      context 'with invalid seasons params' do
        context 'when invalid dates' do
          it 'returns JSON with errors messages' do
            season_params[:end_date] = nil
            is_expected.to be_unprocessable

            expect(json.dig('errors')).to include("seasons.end_date" => ["can't be blank"])
          end
        end

        context 'when overlapping with other season' do
          before(:each) do
            create :group_season, group: group, start_date: date, end_date: date.advance(days: 10)
          end

          it 'returns JSON with errors messages' do
            is_expected.to be_unprocessable

            expect(json.dig('errors')).to include("seasons.start_date" => ["overlaps with other seasons"])
          end
        end
      end
    end
  end

  describe "#destroy" do
    subject { delete :destroy, venue_id: venue.id, id: group.id }

    let!(:group) { create :group, venue: venue, owner: venue.users.first }

    it "deletes group and returns OK" do
      expect{ subject }.to change(Group, :count).by(-1)

      is_expected.to be_success
      expect(json).to eq [group.id]
    end
  end

  describe '#destroy_many' do
    subject{ delete :destroy_many, venue_id: venue.id, **params }

    let!(:group1) { create :group, owner: venue.users.first, venue: venue }
    let!(:group2) { create :group, venue: venue, owner: admin }
    let!(:other_group) { create :group, venue: venue }

    let(:params) { { group_ids: [group1.id, group2.id] } }

    it 'deletes groups' do
      expect{ subject }.to change{ venue.groups.count }.by(-2)

      is_expected.to be_success
      expect(json).to match_array [group1.id, group2.id]
    end
  end

  describe '#duplicate_many' do
    subject{ post :duplicate_many, venue_id: venue.id, **params }

    let!(:group) { create :group, owner: venue.users.first,
                                   venue: venue,
                                   priced_duration: 'season' }
    let!(:season) { create :group_season, group: group, current: true }
    let!(:other_group) { create :group, venue: venue }

    let(:params) { { group_ids: [group.id] } }
    let(:new_group) { venue.groups.last }
    let(:new_season) { new_group.seasons.last }

    it 'duplicates groups with seasons' do
      expect{ subject }.to change{ venue.groups.count }.by(1)
                       .and change{ GroupSeason.count }.by(1)

      is_expected.to be_success
      expect(json).to match_array [group.id]
      expect(new_group.priced_duration).to eq 'season'
      expect(new_season.start_date).to eq season.start_date
    end
  end

  describe "#select_options" do
    subject { get :select_options, venue_id: venue.id  }

    let!(:group1) { create :group, venue: venue }
    let!(:group2) { create :group, venue: venue }
    let!(:other_company_group) { create :group, :with_custom_biller }
    let(:group_ids) { json.map { |option| option['value'] } }

    it 'returns json with groups options' do
      is_expected.to be_success

      expect(group_ids).to eq [group1.id, group2.id]
    end
  end
end
