require 'rails_helper'

describe CustomDevise::OmniauthCallbacksController do
  describe '#facebook' do
    context 'when there was an error creating social account' do
      let(:returned_user) { double(:user, id: 'id', email: 'email@example.com') }
      let(:json_response) { JSON.parse(response.body) }

      before do
        request.env["devise.mapping"] = Devise.mappings[:user]
        request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:facebook]
      end

      it 'renders error as JSON' do
        expect(SocialLoginService).to receive(:from_omniauth).and_return(['social_network_error', returned_user])
        get :facebook
        expect(json_response['error']).to eql 'social_network_error'
        expect(json_response['email']).to eql 'email@example.com'
        expect(json_response['id']).to eql 'id'
        expect(response).to be_unprocessable
      end
    end
  end
end
