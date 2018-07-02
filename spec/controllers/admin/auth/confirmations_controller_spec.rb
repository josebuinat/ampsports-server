require 'rails_helper'

describe Admin::Auth::ConfirmationsController, type: :controller do
  render_views

  let(:body) { JSON.parse response.body }
  let(:password) { Devise.friendly_token.first(8) }
  let(:password_confirmation) { password }

  before(:each) do
    # do not set mapping for coach though!
    request.env['devise.mapping'] = Devise.mappings[:admin]
  end

  context 'when logging in as admin' do
    let(:admin) { create :admin, confirmed_at: nil }
    let(:token) { admin.confirmation_token }

    describe 'GET #show' do
      subject{ get :show, format: :json, confirmation_token: token, password: password, password_confirmation: password_confirmation }

      context 'with correct token' do
        let(:token) { admin.confirmation_token }

        it 'confirms admin record' do
          expect { subject }.to change { admin.reload.confirmed? }.from(false).to(true)
          expect(body.keys).to match ['auth_token', 'message']
          is_expected.to be_success
        end
      end

      context 'with wrong token' do
        let(:token) { 'some random string' }

        it "doesn't confirm admin record" do
          expect { subject }.to do_not_change { admin.reload.confirmed? }
                              .and do_not_change { admin.reload.encrypted_password }

          is_expected.to be_unprocessable
          expect(body).to include('errors' => {'confirmation_token' => [ 'is invalid' ] })
        end
      end

      context 'when admin has password' do
        let!(:admin) { create :admin, confirmed_at: nil,
                                      password: 'password',
                                      password_confirmation: 'password' }
        let(:password_confirmation) { 'some random string' }

        it "confirms admin record" do
          expect { subject }.to change { admin.reload.confirmed? }.from(false).to(true)
          expect(body.keys).to match ['auth_token', 'message']
          is_expected.to be_success
        end

        it "ignores password params and does not upate password" do
          expect { subject }.not_to change { admin.reload.encrypted_password }
          is_expected.to be_success
        end
      end

      context "when admin doesn't have a password" do
        let!(:admin) { create :admin, confirmed_at: nil,
                                      password: nil,
                                      password_confirmation: nil,
                                      without_password: true }

        context 'when passwords match' do
          it 'confirms admin record' do
            expect { subject }.to change { admin.reload.confirmed? }.from(false).to(true)
            expect(body.keys).to match ['auth_token', 'message']
            is_expected.to be_success
          end

          it 'updates password' do
            expect { subject }.to change { admin.reload.encrypted_password }
            is_expected.to be_success
          end
        end

        context "when passwords don't match" do
          let(:password_confirmation) { 'some random string' }

          it "doesn't confirm admin record" do
            expect { subject }.to do_not_change { admin.reload.confirmed? }
                              .and do_not_change { admin.reload.encrypted_password }

            is_expected.to be_unprocessable
            expect(body).to include('errors' => {'password_confirmation' => [ "doesn't match Password" ] })
          end
        end
      end
    end
  end

  context 'when logging in as a coach' do
    let(:coach) { create :coach, confirmed_at: nil }
    let(:token) { coach.confirmation_token }

    describe 'GET #show' do
      subject{ get :show, format: :json, confirmation_token: token, password: password, password_confirmation: password_confirmation }

      context 'with correct token' do
        let(:token) { coach.confirmation_token }

        it 'confirms coach record' do
          expect { subject }.to change { coach.reload.confirmed? }.from(false).to(true)
          expect(body.keys).to match ['auth_token', 'message']
          is_expected.to be_success
        end
      end

      context 'with wrong token' do
        let(:token) { 'some random string' }

        it "doesn't confirm coach record" do
          expect { subject }.to do_not_change { coach.reload.confirmed? }
            .and do_not_change { coach.reload.encrypted_password }

          is_expected.to be_unprocessable
          expect(body).to include('errors' => {'confirmation_token' => [ 'is invalid' ] })
        end
      end

      context 'when coach has password' do
        let!(:coach) { create :coach, confirmed_at: nil,
          password: 'password',
          password_confirmation: 'password' }
        let(:password_confirmation) { 'some random string' }

        it "confirms coach record" do
          expect { subject }.to change { coach.reload.confirmed? }.from(false).to(true)
          expect(body.keys).to match ['auth_token', 'message']
          is_expected.to be_success
        end

        it "ignores password params and does not upate password" do
          expect { subject }.not_to change { coach.reload.encrypted_password }
          is_expected.to be_success
        end
      end

      context "when coach doesn't have a password" do
        let!(:coach) { create :coach, confirmed_at: nil,
          password: nil,
          password_confirmation: nil,
          without_password: true }

        context 'when passwords match' do
          it 'confirms coach record' do
            expect { subject }.to change { coach.reload.confirmed? }.from(false).to(true)
            expect(body.keys).to match ['auth_token', 'message']
            is_expected.to be_success
          end

          it 'updates password' do
            expect { subject }.to change { coach.reload.encrypted_password }
            is_expected.to be_success
          end
        end

        context "when passwords don't match" do
          let(:password_confirmation) { 'some random string' }

          it "doesn't confirm coach record" do
            expect { subject }.to do_not_change { coach.reload.confirmed? }
              .and do_not_change { coach.reload.encrypted_password }

            is_expected.to be_unprocessable
            expect(body).to include('errors' => {'password_confirmation' => [ "doesn't match Password" ] })
          end
        end
      end
    end
  end
end
