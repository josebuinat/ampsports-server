require 'rails_helper'

describe Admin::Companies::CouponsController, type: :controller do
  render_views

  describe "GET show" do
    subject { get :show, format: :json, code: code }
    let!(:coupon) { create :coupon, code: 'whatsUP' }

    context 'with existing code' do
      let(:code) { 'WHATSup' }

      it { is_expected.to be_success }
    end

    context 'with unexisting code' do
      let(:code) { 'whatsDOWN' }

      it { is_expected.to be_not_found }
    end
  end
end
