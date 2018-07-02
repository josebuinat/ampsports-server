require "rails_helper"

describe Admin::GroupCustomBillersController, type: :controller do
  render_views
  let!(:admin) { create :admin, :with_company }
  let!(:company) { admin.company }
  let!(:venue) { create :venue, company: company }
  let!(:group) { create :group, :with_custom_biller, venue: venue }

  let(:valid_params) do
    {
      company_legal_name: 'Test Company valid',
      company_business_type: 'OY valid',
      company_tax_id: 'FI2381233 valid',
      bank_name: 'best bank valid',
      company_bic: '34536758345633 454',
      company_iban: 'GR16 0110 1250 0000 0001 2300 695 3453',
      country_id: 2,
      company_street_address: 'Mannerheimintie 5 valid',
      company_zip: '99099',
      company_city: 'Helsinki valid',
      company_website: 'www.testcompany.com.valid',
      company_phone: '+98304598637056',
      invoice_sender_email: 'test-valid@test.test',
      group_ids: [group.id],
    }
  end
  let(:invalid_params) { valid_params.merge(company_legal_name: nil) }

  before { sign_in_for_api_with admin }

  describe "#index" do
    subject { get :index }
    let!(:other_group) { create :group, :with_custom_biller, venue: venue }
    let!(:other_company_group) { create :group, :with_custom_biller }

    let!(:group_custom_biller1) { group.custom_biller }
    let!(:group_custom_biller2) { other_group.custom_biller }
    let!(:other_company_group_custom_biller2) { other_company_group.custom_biller }

    let(:custom_biller_ids) { json['group_custom_billers'].map { |x| x['id'] } }

    it 'returns group custom billers JSON' do
      is_expected.to be_success
      expect(custom_biller_ids).to eq [group_custom_biller1.id, group_custom_biller2.id]
    end
  end

  describe "#show" do
    subject { get :show, id: group_custom_biller.id }

    let!(:group_custom_biller) { group.custom_biller }

    it 'returns JSON with error if not found' do
      group_custom_biller.id = 'not existing'

      is_expected.to be_not_found
      expect(json['errors']).to include(I18n.t('api.record_not_found'))
    end

    it 'returns JSON with data' do
      is_expected.to be_success
      expect(json).to include('id' => group_custom_biller.id,
                              'company_legal_name' => 'Test Company',
                              'group_ids' => [group.id])
    end
  end

  describe "#create" do
    subject { post :create, params }
    before{ group.custom_biller.destroy }

    let!(:params) { { group_custom_biller: valid_params } }
    let(:new_custom_biller) { company.group_custom_billers.last }

    context 'with valid data' do
      it 'creates group custom biller for group' do
        expect{ subject }.to change{ company.group_custom_billers.reload.count }.by(1)

        expect(new_custom_biller.groups).to include(group)
        expect(json['id']).to eq new_custom_biller.id
      end
    end

    context 'with invalid data' do
      let!(:params) { { group_custom_biller: invalid_params } }

      it 'returns JSON with errors messages' do
        is_expected.to be_unprocessable

        expect(json['errors']).to include("company_legal_name" => ["can't be blank"])
      end
    end
  end

  describe "#update" do
    subject { put :update, id: group_custom_biller.id, **params }

    let!(:group_custom_biller) { group.custom_biller }

    let!(:params) { { group_custom_biller: valid_params } }

    context 'with valid params' do
      it 'saves params to group custom biller' do
        expect{ subject }.to change { group_custom_biller.reload.company_legal_name }.
                                      to('Test Company valid')

        is_expected.to be_success
      end
    end

    context 'with invalid data' do
      let!(:params) { { group_custom_biller: invalid_params } }

      it 'returns JSON with errors messages' do
        is_expected.to be_unprocessable

        expect(json['errors']).to include("company_legal_name" => ["can't be blank"])
      end
    end
  end

  describe "#destroy" do
    subject{ delete :destroy, id: group_custom_biller.id }

    let!(:group_custom_biller) { group.custom_biller }

    it "deletes group_custom_biller and returns OK" do
      expect{ subject }.to change(GroupCustomBiller, :count).by(-1)
      is_expected.to be_success
    end
  end

  describe "#groups_options" do
    subject { get :groups_options }

    let!(:group_without_biller) { create :group, venue: venue }
    let!(:other_company_group) { create :group, :with_custom_biller }

    it 'returns json with groups data' do
      is_expected.to be_success

      expect(json.map { |group| group['value'] }).to include(group_without_biller.id)
    end

    it 'does not return groups with custom biller' do
      is_expected.to be_success

      expect(json.map { |group| group['value'] }).not_to include(group.id)
    end

    it 'does not return groups from other company' do
      is_expected.to be_success

      expect(json.map { |group| group['value'] }).not_to include(other_company_group.id)
    end
  end

  describe '#destroy_many' do
    subject{ delete :destroy_many, **params }

    let!(:group1) { create :group, :with_custom_biller, venue: venue, owner: admin }
    let!(:group2) { create :group, :with_custom_biller, venue: venue, owner: admin }
    let!(:other_company_group) { create :group, :with_custom_biller }

    let(:custom_biller_ids) { [group1.custom_biller.id, group2.custom_biller.id] }
    let(:params) { { group_custom_biller_ids: custom_biller_ids } }

    it 'deletes groups' do
      expect{ subject }.to change{ company.group_custom_billers.count }.by(-2)

      is_expected.to be_success
      expect(json).to match_array custom_biller_ids
    end
  end
end
