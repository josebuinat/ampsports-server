require "rails_helper"

describe API::Users::SettingsController, type: :controller do
  render_views
  before { sign_in_for_api_with(current_user) }
  let(:current_user) { create :user }
  let(:settings_scope) { 'email_notifications' }

  describe '#index' do
    subject { get :index, { user_id: current_user.id, scope: settings_scope } }

    context 'with an invalid scope' do
      let(:settings_scope) { 'invalid' }

      it 'returns error' do
        is_expected.to be_unprocessable
        expect(json['errors']).to include(I18n.t('errors.settings.invalid_scope'))
      end
    end

    context "with email_notifications scope" do
      it 'returns mailing settings' do
        is_expected.to be_success
        expect(json['email_notifications']).to include('name' => 'reservation_receipts', 'value' => true)
      end
    end
  end

  describe '#update' do
    subject { patch :update, { user_id: current_user.id, scope: settings_scope, **params } }
    let(:params) do
      {
        name: 'reservation_receipts',
        value: false
      }
    end

    context 'with an invalid scope' do
      let(:settings_scope) { 'invalid' }

      it 'returns error' do
        is_expected.to be_unprocessable
        expect(json['errors']).to include(I18n.t('errors.settings.invalid_scope'))
      end
    end

    context 'with an invalid name' do
      let(:params) do
        {
          name: 'invalid name',
          value: false
        }
      end

      it 'returns error' do
        is_expected.to be_not_found
        expect(json['errors']).to include(I18n.t('errors.settings.invalid_name'))
      end
    end

    context "with email_notifications scope" do
      it 'updated value and returns mailing settings' do
        expect{ subject }.to change { Setting.count }.by(1)
          .and change{ current_user.settings(:email_notifications).reload.get(:reservation_receipts) }.from(true).to(false)
        is_expected.to be_success
        expect(json['email_notifications']).to include('name' => 'reservation_receipts', 'value' => false)
      end

      context 'with an invalid value' do
        let(:params) do
          {
            name: 'reservation_receipts',
            value: nil
          }
        end

        it 'returns error' do
          is_expected.to be_unprocessable
          expect(json['errors']).to include(I18n.t('errors.settings.update_failed'))
        end
      end
    end
  end
end
