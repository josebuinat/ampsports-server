require 'rails_helper'

describe API::AuthController, type: :controller do
  include ActiveSupport::Testing::TimeHelpers

  describe "#authenticate" do
    subject { post :authenticate, format: :json, **params }

    let(:password) { 'supersecret123' }
    let(:user) { create :user, password: password, password_confirmation: password }
    let(:params) { { email: user.email, password: password } }
    let(:parsed_response) { JSON.parse(subject.body).with_indifferent_access }
    let(:response_auth_token) { parsed_response['auth_token'] }
    let(:decoded_auth_token) { AuthToken.decode(response_auth_token) }

    context "with valid params" do
      it 'authenticates user' do
        is_expected.to be_success
        expect(decoded_auth_token).to include user.attributes.slice(:id, :email, :first_name, :last_name)
      end
    end

    context "with invalid params" do
      let(:params) { { email: user.email, password: 'incorrect-password' } }

      it 'renders error' do
        is_expected.to be_unauthorized
        expect(parsed_response).to include errors: ['Invalid username or password']
        expect(response_auth_token).to be_blank
      end
    end

    context 'with unconfirmed user having password' do
      let(:user) { create :user, password: password, password_confirmation: password, confirmed_at: nil }

      it 'authenticates user' do
        is_expected.to be_success
        expect(decoded_auth_token).to include user.attributes.slice(:id, :email, :first_name, :last_name)
      end
    end
  end

  describe '#renew_token' do
    subject { post :renew_token, format: :json }

    let(:user) { create(:user) }
    let(:parsed_response) { JSON.parse(subject.body).with_indifferent_access }
    let(:response_auth_token) { parsed_response[:auth_token] }

    # for this test we are not stubbing anything, we issue a real tokens
    before do
      travel_to token_issued_at do
        token = user.authentication_payload[:auth_token]
        @request.headers.merge!({ 'Authorization' => "Bearer #{token}"})
      end
    end

    context 'when user token is valid' do
      let(:token_issued_at) { 15.days.ago }
      let(:decoded_auth_token) { AuthToken.decode(response_auth_token).with_indifferent_access }
      let(:time_to_live_in_seconds) { AuthToken::DEFAULT_TTL * 60 }

      it 'responds with a fresh token' do
        is_expected.to be_success
        seconds_to_expire = decoded_auth_token['exp'] - Time.now.to_i
        # time to expire should be + - 10 seconds of 30 days
        expect(seconds_to_expire).to be_within(10).of(time_to_live_in_seconds)
      end
    end

    context 'when user token is expired' do
      let(:token_issued_at) { 40.days.ago }
      it 'renders a error' do
        expect(response_auth_token).to be_blank
        # 419 = authentication timeout, no symbol/keyword for this in Rails
        expect(response.code).to eq '419'
      end
    end
  end
end
