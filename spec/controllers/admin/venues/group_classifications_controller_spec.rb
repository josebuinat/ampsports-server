require "rails_helper"

describe Admin::Venues::GroupClassificationsController, type: :controller do
  render_views
  let!(:admin) { create :admin, :with_company }
  let!(:company) { admin.company }
  let!(:venue) { create :venue, company: company }

  before { sign_in_for_api_with admin }

  describe "#index" do
    subject{ get :index, venue_id: venue.id }

    let!(:group_classification1) { create :group_classification, venue: venue }
    let!(:group_classification2) { create :group_classification, venue: venue }
    let!(:other_venue_group_classification) { create :group_classification }

    let(:group_classification_ids) { json['group_classifications'].map { |x| x['id'] } }

    it 'returns group_classifications JSON' do
      is_expected.to be_success
      expect(group_classification_ids).to match_array [group_classification1.id, group_classification2.id]
    end

    context 'when sorted on name' do
      subject{ get :index, venue_id: venue.id, sort_on: 'name desc' }

      it 'returns sorted classifications' do
        is_expected.to be_success
        expect(group_classification_ids).to eq [group_classification2.id, group_classification1.id]
      end
    end
  end

  describe "#show" do
    subject{ get :show, venue_id: venue.id, id: group_classification.id }

    let!(:group_classification) { create :group_classification, venue: venue }

    it 'returns JSON with error if group_classification not found' do
      group_classification.id = 'not existing'

      is_expected.to be_not_found
      expect(json['errors']).to include(I18n.t('api.record_not_found'))
    end

    it 'returns JSON with group_classification data' do
      is_expected.to be_success
      expect(json).to include('id' => group_classification.id,
                              'name' => group_classification.name)
    end
  end

  describe "#create" do
    subject{ post :create, params }

    let!(:params) { {
      venue_id: venue.id,
      group_classification: {
        name: new_name,
        price: 10,
        price_policy: 'hourly',
      }
    } }
    let(:new_name) { 'group_classification name' }
    let(:new_group_classification) { venue.group_classifications.last }

    context 'with valid data' do
      it 'creates group classification for venue' do
        expect{ subject }.to change(GroupClassification, :count).by(1)

        is_expected.to be_created

        expect(json['id']).to eq new_group_classification.id
        expect(new_group_classification.name).to eq params[:group_classification][:name]
      end
    end

    context 'with invalid data' do
      let(:new_name) { nil }

      it 'returns JSON with errors messages' do
        is_expected.to be_unprocessable

        expect(json['errors']).to include('name' => ["can't be blank"])
      end
    end
  end

  describe "#update" do
    subject{ put :update, params }

    let!(:group_classification) { create :group_classification, venue: venue }

    let!(:params) {{
      id: group_classification.id,
      venue_id: venue.id,
      group_classification: {
        name: new_name,
      }
    }}
    let(:new_name) { 'new name' }

    context 'with valid params' do
      it 'updates group_classification' do
        is_expected.to be_success

        expect(json).to include('id' => group_classification.id)
        expect(group_classification.reload.name).to eq params[:group_classification][:name]
      end
    end

    context 'with invalid data' do
      let(:new_name) { nil }

      it 'returns JSON with errors messages' do
        is_expected.to be_unprocessable

        expect(json['errors']).to include('name' => ["can't be blank"])
      end
    end
  end

  describe "#destroy" do
    subject{ delete :destroy, venue_id: venue.id, id: group_classification.id }

    let!(:group_classification) { create :group_classification, venue: venue }

    it "deletes group classification and returns OK" do
      expect{ subject }.to change(GroupClassification, :count).by(-1)

      is_expected.to be_success
      expect(json).to eq [group_classification.id]
    end
  end

  describe '#destroy_many' do
    subject{ delete :destroy_many, venue_id: venue.id, **params }

    let!(:group_classification1) { create :group_classification, venue: venue }
    let!(:group_classification2) { create :group_classification, venue: venue }
    let!(:other_group_classification) { create :group_classification, venue: venue }

    let(:classification_ids) { [group_classification1.id, group_classification2.id] }
    let(:params) { { group_classification_ids: classification_ids } }

    it 'deletes groups' do
      expect{ subject }.to change{ venue.group_classifications.count }.by(-2)

      is_expected.to be_success
      expect(json).to match_array classification_ids
    end
  end
end
