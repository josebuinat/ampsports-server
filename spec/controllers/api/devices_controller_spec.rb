require 'rails_helper'

describe API::DevicesController, type: :controller do
  let(:user) { create(:user, :with_devices) }

  let(:token) { 'test_token' }
  let(:params) { { device: { token: token }} }

  before do
    sign_in_for_api_with user
  end

  describe 'POST create' do
    subject { post :create, params}
    it 'is successfull' do
      expect(subject.status).to eq(200)
    end

    it 'creates device' do
      expect { subject }.to change{user.reload.devices.count}.by(1)
    end

    it 'has to have token' do
      params[:device][:token] = nil
      expect(subject.status).to eq(400)
    end
  end

  describe 'DELETE destroy' do
    subject { delete :destroy }

    before do
      request.headers.merge!({ 'device_token' => token })
    end

    it 'is successful' do
      expect(subject.status).to eq(200)
    end
    
    it 'destroys device' do
      expect { subject }.to change{user.reload.devices.count}.by(-1)
    end

    it 'fails silently with no token' do
      request.headers.merge!({ 'device_token' => nil })
      expect { subject }.to change{user.reload.devices.count}.by(0)
      expect(subject.status).to eq(200)
    end
  end
end
