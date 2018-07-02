require 'rails_helper'

describe Admin::Auth::PasswordsController, type: :controller do
  render_views

  let(:body) { JSON.parse response.body }

  before(:each) do
    # do not set mapping to coach though
    request.env["devise.mapping"] = Devise.mappings[:admin]
  end

  context 'when resetting password as an admin' do
    let(:current_admin) { create :admin }

    describe 'POST #create' do
      subject{ post :create, format: :json, admin: { email: email } }

      context 'correct email' do
        let(:email) { current_admin.email }

        it 'sends reset password mail' do
          expect(Devise::Mailer).to receive_message_chain(:reset_password_instructions, :deliver)

          is_expected.to be_created
        end
      end

      context 'incorrect email' do
        let(:email) { 'incorrect@email.test' }

        it 'rejects with error' do
          expect(Devise::Mailer).not_to receive(:reset_password_instructions)

          is_expected.to be_unprocessable

          expect(body['errors']).to include({ "email" => [ "not found" ] })
        end
      end
    end


    describe 'POST #update' do
      subject{ patch :update, format: :json, admin: params }

      let!(:reset_password_token) { current_admin.send_reset_password_instructions }
      let(:params) do
        {
          password: 'password',
          password_confirmation: password_confirmation,
          reset_password_token: reset_password_token
        }
      end
      let(:password_confirmation) { 'password' }

      context 'with valid token' do
        it 'updates password' do
          expect{ subject }.to change{ current_admin.reload.encrypted_password }

          is_expected.to be_success
        end
      end

      context 'with invalid token' do
        let(:reset_password_token) { '' }

        it "doesn't update password" do
          expect{subject}.not_to change{ current_admin.reload.encrypted_password }

          is_expected.to be_unprocessable
          expect(body['errors']).to include({ "reset_password_token" => [ "is not valid" ] })
        end
      end

      context "when password confirmation doesn't match password" do
        let(:password_confirmation) { 'not a password' }

        it "doesn't update password" do
          expect{ subject }.not_to change{ current_admin.reload.encrypted_password }

          is_expected.to be_unprocessable
          expect(body['errors']).to include({ "password_confirmation" => [ "doesn't match Password" ] })
        end
      end
    end
  end

  context 'when resetting password as a coach' do
    let(:current_coach) { create :coach }

    describe 'POST #create' do
      subject{ post :create, format: :json, admin: { email: email } }

      context 'correct email' do
        let(:email) { current_coach.email }

        it 'sends reset password mail' do
          expect(Devise::Mailer).to receive_message_chain(:reset_password_instructions, :deliver)

          is_expected.to be_created
        end
      end

      context 'incorrect email' do
        let(:email) { 'incorrect@email.test' }

        it 'rejects with error' do
          expect(Devise::Mailer).not_to receive(:reset_password_instructions)

          is_expected.to be_unprocessable

          expect(body['errors']).to include({ "email" => [ "not found" ] })
        end
      end
    end


    describe 'POST #update' do
      subject{ patch :update, format: :json, admin: params }

      let!(:reset_password_token) { current_coach.send_reset_password_instructions }
      let(:params) do
        {
          password: 'password',
          password_confirmation: password_confirmation,
          reset_password_token: reset_password_token
        }
      end
      let(:password_confirmation) { 'password' }

      context 'with valid token' do
        it 'updates password' do
          expect{ subject }.to change{ current_coach.reload.encrypted_password }

          is_expected.to be_success
        end
      end

      context 'with invalid token' do
        let(:reset_password_token) { '' }

        it "doesn't update password" do
          expect{subject}.not_to change{ current_coach.reload.encrypted_password }

          is_expected.to be_unprocessable
          expect(body['errors']).to include({ "reset_password_token" => [ "is not valid" ] })
        end
      end

      context "when password confirmation doesn't match password" do
        let(:password_confirmation) { 'not a password' }

        it "doesn't update password" do
          expect{ subject }.not_to change{ current_coach.reload.encrypted_password }

          is_expected.to be_unprocessable
          expect(body['errors']).to include({ "password_confirmation" => [ "doesn't match Password" ] })
        end
      end
    end
  end
end
