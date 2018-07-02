require 'rails_helper'

describe Admin::Auth::RegistrationsController, type: :controller do
  render_views

  describe 'POST #create' do
    subject { post :create, admin: params }

    let(:params) { {
      password: password,
      password_confirmation: password,
      email: 'test@test.test',
      first_name: 'John',
      last_name: 'Doe',
      company_legal_name: company_legal_name
    } }

    let(:password) { 'password' }
    let(:company_legal_name) { 'Sacred Hospital' }
    let(:body) { JSON.parse response.body }
    let(:created_company) { Company.last }
    let(:created_admin) { Admin.last }
    before(:each) do
      request.env["devise.mapping"] = Devise.mappings[:admin]
    end

    context 'when valid params' do
      it 'creates admin' do
        expect{ subject }.to change { Admin.count }.by(1)
        is_expected.to be_created
        expect(created_admin.level).to eq 'god'
      end

      it 'returns auth token' do
        is_expected.to be_created

        expect(body.dig('auth_token')).to be_present
      end

      it "encodes clock format" do
        expect(AuthToken).to receive(:encode).with(a_hash_including(clock_type: "24h"), any_args).and_return('abc123')
        expect { subject }.to change(Admin, :count).by(1)
      end

      it 'creates a company' do
        expect { subject }.to change { Company.count }.by(1)
        is_expected.to be_created
        expect(created_company.company_legal_name).to eq params[:company_legal_name]
        expect(created_company.admins).to include created_admin
      end
    end

    context 'when invalid params' do

      context 'with error on an admin record' do
        let(:password) { '' }

        it 'neither creates admin nor company' do
          expect{ subject }.to do_not_change { Admin.count }.
              and do_not_change { Company.count }
          is_expected.to be_unprocessable
        end
      end

      context 'with error on an company record' do
        let(:company_legal_name) { '' }

        it 'neither creates admin nor company' do
          expect{ subject }.to do_not_change { Admin.count }.
            and do_not_change { Company.count }
          is_expected.to be_unprocessable
        end
      end
    end
  end
end
