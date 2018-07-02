require 'rails_helper'
require 'stripe_mock'

describe Admin::CompanyController, type: :controller do
  render_views

  let(:current_admin) { create :admin, :with_company }
  let(:company) { current_admin.company }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:body) { JSON.parse response.body }

  describe 'GET #show' do
    subject { get :show, format: :json }
    before { sign_in_for_api_with current_admin }

    it { is_expected.to be_success }

    context 'when company not created yet' do
      before { current_admin.update_attribute(:company_id, nil) }
      it { is_expected.to be_not_found }
    end
  end

  describe 'PATCH #update' do
    subject { patch :update, format: :json, company: params }
    before { sign_in_for_api_with current_admin }

    let(:params) { { company_legal_name: 'Foo bar co' } }
    it 'works' do
      expect { subject }.to change { company.reload.company_legal_name }.
        to(params[:company_legal_name])
      is_expected.to be_success
    end
  end

  context 'when user is not god' do
    describe 'GET #show' do
      subject { get :show, format: :json }

      let!(:company) { create :company }
      let!(:god_admin) { create :admin, company: company }
      let(:current_admin) { create :admin, company: company, level: :manager }

      before { sign_in_for_api_with current_admin }

      it 'kicks' do
        is_expected.to be_not_found
      end
    end
  end
end
