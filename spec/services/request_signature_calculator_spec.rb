require 'rails_helper'

describe RequestSignatureCalculator do
  describe '#call' do
    subject { described_class.(request, app_name) }
    let(:request) { double("ActionDispatch::Request", fullpath: '/path/') }
    let(:app_name) { 'test-app-name' }

    context 'with wrong name' do
      # no app created at this point
      it 'raises error' do
        expect { subject }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'with correct name' do
      let!(:api_secret_key) { create :api_secret_key, name: app_name }
      let(:correct_response) { Digest::MD5.hexdigest('/path/' + api_secret_key.key) }
      it 'returns correct response' do
        is_expected.to eq correct_response
      end
    end
  end
end