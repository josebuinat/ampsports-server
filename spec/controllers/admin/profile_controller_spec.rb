require 'rails_helper'

describe Admin::ProfileController, type: :controller do
  render_views

  let(:company) { create :company }
  let!(:current_admin) { create :admin, company: company }
  describe '#update' do
    before { sign_in_for_api_with current_admin }
    subject { patch :update, admin: params, format: :json }
    let(:params) { { first_name: 'hey', last_name: 'you' } }

    it 'works' do
      expect { subject }.to change { current_admin.reload.first_name }.to('hey').
          and change { current_admin.reload.last_name }.to('you')

      is_expected.to be_success
    end

    context 'when changing password' do
      let(:password) { 'testpassword2' }
      let(:password_confirmation) { 'testpassword2' }
      let(:current_password) { 'testpassword' }
      let(:params) do
        { password: password,
          password_confirmation: password_confirmation,
          current_password: current_password }
      end
      context 'when current password is incorrect' do
        let(:current_password) { 'wrngpasswrd' }
        it 'does not work' do
          expect { subject }.to_not change { current_admin.reload.encrypted_password }
          is_expected.to be_unprocessable
        end
      end

      context 'when current password is correct' do
        it 'works' do
          expect { subject }.to change { current_admin.reload.encrypted_password }
          is_expected.to be_success
        end
      end

      context 'when confirmation mismatch' do
        let(:password_confirmation) { 'nopenotthistime' }
        it 'does not work' do
          expect { subject }.to_not change { current_admin.reload.encrypted_password }
          is_expected.to be_unprocessable
        end
      end
    end
  end
end