require "rails_helper"

describe 'Request Signature', type: :request, sign_requests: true do

  describe "GET index" do
    let!(:current_user) { create :user }
    let(:md5_signature) { 'nice-md5-hased-signature' }
    let(:app_name) { 'test-app' }
    before { sign_in current_user }

    let(:headers) { { 'signature' => md5_signature, 'app-name' => app_name } }
    # use random existing URL under /api, not important which one
    subject { get '/api/all_sport_names', nil, headers }

    context 'with correct signature' do
      before do
        allow(RequestSignatureCalculator).to receive(:call).and_return(md5_signature)
      end

      it { is_expected.not_to eq 412 }
    end

    context 'with nonexistent app' do
      # we don't have an "test-app" app at this point
      # it { is_expected.to eq 412 }

      # playing safe now, re-comment when changed back to real validation
      it { is_expected.to eq 200 }
    end

    context 'with existing app, but wrong signature' do
      let!(:api_secret_key) { create :api_secret_key, name: app_name }
      # it { is_expected.to eq 412 }

      # playing safe now, re-comment when changed back to real validation
      it { is_expected.to eq 200 }
    end
  end
end
