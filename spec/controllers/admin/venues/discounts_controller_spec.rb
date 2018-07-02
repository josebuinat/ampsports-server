require 'rails_helper'

describe Admin::Venues::DiscountsController, type: :controller do
  render_views

  let!(:company) { create :company }
  let!(:venue) { create :venue, company: company }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }

  let(:body) { JSON.parse response.body }

  describe '#index' do
    subject { get :index, format: :json, venue_id: venue.id }
    let(:discount_ids) { body['discounts'].map { |x| x['id'] } }
    let!(:discount) { create :discount, venue: venue }

    it 'works' do
      is_expected.to be_success
      expect(discount_ids).to eq [discount.id]
    end
  end

  describe '#show' do
    subject { get :show, format: :json, venue_id: venue.id, id: discount.id }
    let!(:discount) { create :discount, venue: venue }
    it { is_expected.to be_success }
  end

  describe '#create' do
    subject { post :create, format: :json, venue_id: venue.id, discount: params }
    context 'with valid params' do
      let(:params) { { method: 'fixed', name: 'sample', value: 100 } }
      it 'creates a discount' do
        expect { subject }.to change { venue.discounts.count }.by(1)
        is_expected.to be_created
      end
    end

    context 'with invalid params' do
      # error: no metod
      let(:params) { { name: 'sample', value: -100 } }
      it 'does not work' do
        expect { subject }.not_to change { venue.discounts.count }
        is_expected.to be_unprocessable
      end
    end
  end

  describe '#update' do
    subject { patch :update, format: :json, venue_id: venue.id, id: discount.id, discount: params }
    let!(:discount) { create :discount, venue: venue }
    context 'with valid params' do
      let(:params) { { name: 'other name' } }
      it 'works' do
        expect { subject }.to change { discount.reload.name }.to('other name')
        is_expected.to be_success
      end
    end

    context 'with invalid params' do
      let(:params) { { name: '' } }
      it 'does not work' do
        expect { subject }.not_to change { discount.reload.attributes }
        is_expected.to be_unprocessable
      end
    end
  end

  describe '#destroy' do
    subject { delete :destroy, format: :json, venue_id: venue.id, id: discount.id }
    let!(:discount) { create :discount, venue: venue }

    it 'works' do
      expect { subject }.to change { venue.discounts.count }.by(-1)
      is_expected.to be_success
    end

  end

  describe '#destroy_many' do
    subject { delete :destroy_many, format: :json, venue_id: venue.id, discount_ids: discount_ids }
    let!(:discount_1) { create :discount, venue: venue }
    let!(:discount_2) { create :discount, venue: venue }
    let(:discount_ids) { [discount_1.id, discount_2.id] }
    it 'works' do
      expect { subject }.to change { venue.discounts.count }.by(-2)
      is_expected.to be_success
    end
  end
end
