require 'rails_helper'

describe Admin::Companies::AdminsController, type: :controller do
  render_views

  let!(:company) { create :company }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }

  describe 'GET #index' do
    subject { get :index, format: :json }
    let!(:other_admin) { create :admin, company: company, level: :manager }
    let!(:unrelated_admin) { create :admin, :with_company, level: :manager }
    let(:body) { JSON.parse response.body }
    let(:admin_ids) { body['admins'].map { |x| x['id'] } }

    it 'renders all admins' do
      is_expected.to be_success
      expect(admin_ids).to match_array [current_admin.id, other_admin.id]
    end

    context 'when coach tries to access' do
      let(:current_admin) { create :coach, company: company }

      it 'renders none of admins' do
        is_expected.to be_success
        expect(admin_ids).to eq []
      end
    end
  end

  describe 'GET #show' do
    subject { get :show, format: :json, id: other_admin.id }

    context 'with admin from same company' do
      let(:other_admin) { create :admin, company: company, level: :manager }
      it { is_expected.to be_success}
    end

    context 'with admin from other company' do
      let(:other_admin) { create :admin, :with_company, level: :manager }
      it { is_expected.to be_not_found }
    end
  end

  describe 'POST #create' do
    subject { post :create, format: :json, admin: params }

    context 'with incorrect params' do
      # just email, need other params too
      let(:params) { { email: 'how@wow.com' } }
      it { is_expected.to be_unprocessable }
    end

    context 'with correct params' do
      let(:params) { attributes_for(:admin, level: :manager).except(:admin_ssn) }

      it 'works' do
        expect { subject }.to change(Admin, :count).by(1)
        is_expected.to be_created
      end
    end
  end

  describe 'PATCH #update' do
    subject { patch :update, id: other_admin.id, admin: params, format: :json }

    context 'with admin from my company' do
      let(:other_admin) { create :admin, level: :manager, company: company }
      context 'with valid params' do
        let(:params) { { first_name: 'Todd' } }

        it 'works' do
          expect { subject }.to change { other_admin.reload.first_name }.to 'Todd'
          is_expected.to be_success
        end
      end

      context 'with invalid params' do
        let(:params) { { email: '' } }

        it 'does not work' do
          expect { subject }.not_to change { other_admin.reload.email }
          is_expected.to be_unprocessable
        end
      end
    end

    context 'with admin from other company' do
      let(:other_admin) { create :admin, :with_company, level: :manager }
      let(:params) { attributes_for :admin }
      it 'does not work' do
        expect { subject }.not_to change { other_admin.reload.attributes }
        is_expected.to be_not_found
      end
    end

    context 'when updating my own authorization level' do
      let(:other_admin) { current_admin }
      let(:params) { { level: 'cashier' } }

      it 'will not change' do
        expect { subject }.not_to change { other_admin.reload.attributes[:level] }
        is_expected.to be_success
      end
    end

    context 'with permissions' do
      let(:other_admin) { create :admin, company: company, level: :guest }
      let(:params) { { permissions: { admins: [:read, :edit] } } }

      it 'makes guest like god' do
        is_expected.to be_success

        expect(json['permissions']).to include('admins' => ['read', 'edit'])
      end
    end
  end

  describe '#destroy' do
    subject { delete :destroy, id: other_admin.id, format: :json }

    context 'when trying to delete myself' do
      let!(:other_admin) { current_admin }
      it 'does not work' do
        expect { subject }.not_to change(Admin, :count)
        is_expected.to be_bad_request
      end
    end

    context 'when deleting someone from my company' do
      let!(:other_admin) { create :admin, company: company, level: :manager }
      it 'works' do
        expect { subject }.to change(Admin, :count).by(-1)
        is_expected.to be_success
      end
    end

    context 'when deleting someone from other company' do
      let!(:other_admin) { create :admin, :with_company, level: :manager }
      it 'does not work' do
        expect { subject }.not_to change(Admin, :count)
        is_expected.to be_not_found
      end
    end
  end

end
