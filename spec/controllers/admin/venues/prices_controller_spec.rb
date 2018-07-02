require 'rails_helper'

describe Admin::Venues::PricesController, type: :controller do
  render_views

  let!(:company) { create :company }
  let!(:venue) { create :venue, company: company }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }

  let(:body) { JSON.parse response.body }

  describe '#index' do
    let!(:court) { create :court, :with_prices, venue: venue }
    subject { get :index, format: :json, venue_id: venue.id }
    let(:price_ids) { body.map { |x| x['id'] } }

    it 'works' do
      is_expected.to be_success
      expect(price_ids).to eq court.prices.pluck(:id)
    end
  end

  describe '#show' do
    let!(:court) { create :court, :with_prices, venue: venue }
    let(:price) { court.prices.first }
    subject { get :show, format: :json, venue_id: venue.id, id: price.id }
    it { is_expected.to be_success }
  end

  describe '#create' do
    subject { post :create, format: :json, venue_id: venue.id, price: params }
    let!(:court_1) { create :court, venue: venue }
    let!(:court_2) { create :court, venue: venue }
    let(:conflicting_prices) { (body['conflicts'] || []).map { |x| x['id'] } }
    let(:days) { %i(monday tuesday wednesday) }
    context 'with valid params' do
      let(:params) { { start_time: '6:00', end_time: '8:00', court_ids: [court_1.id, court_2.id], price: 10, days: days }}
      let(:created_price) { venue.prices.last }
      it 'creates a price' do
        expect { subject }.to change { venue.prices.reload.uniq.size }.by(1)
        expect(created_price.courts).to match_array [court_1, court_2]
        expect(created_price.days).to match_array days
        is_expected.to be_created
        expect(conflicting_prices).to be_blank
      end

      context 'with conflicting prices' do
        let!(:price_1) { create(:price, monday: true, start_time: '7:00', end_time: '9:00', courts: [court_1, court_2]) }
        let!(:price_2) { create(:price, wednesday: true, start_time: '6:00', end_time: '7:00', courts: [court_2]) }

        it 'renders conflicting prices' do
          expect { subject }.not_to change(Price, :count)
          is_expected.to be_unprocessable
          expect(conflicting_prices).to match_array [price_1.id, price_2.id]
        end
      end
    end

    context 'with invalid params' do
      # error: end time < start_time
      let(:params) { { start_time: '12:00', end_time: '10:00', court_ids: [court_1.id], days: days }}
      it 'does not work' do
        expect { subject }.not_to change(Price, :count)
        is_expected.to be_unprocessable
        expect(conflicting_prices).to be_blank
      end
    end
  end

  describe '#update' do
    subject { patch :update, format: :json, venue_id: venue.id, id: price.id, price: params }
    let!(:court_1) { create :court, venue: venue }
    let!(:court_2) { create :court, venue: venue }
    let!(:price) { create :price, courts: [court_1], start_time: '10:00', end_time: '11:00', monday: true }
    let(:conflicting_prices) { (body['conflicts'] || []).map { |x| x['id'] } }
    let(:days) { %i(monday tuesday wednesday) }

    context 'with valid params' do
      let(:params) { { start_time: '6:00', end_time: '8:00', court_ids: [court_1.id, court_2.id], price: 10, days: days }}
      let(:created_price) { venue.prices.last }

      it 'updates a price' do
        expect { subject }.to change { price.reload.courts.reload }.by([court_2])
        is_expected.to be_success
        expect(conflicting_prices).to be_blank
      end

      context 'with conflicting prices' do
        let!(:price_1) { create(:price, monday: true, start_time: '7:00', end_time: '9:00', courts: [court_1, court_2]) }
        let!(:price_2) { create(:price, wednesday: true, start_time: '6:00', end_time: '7:00', courts: [court_2]) }
        let(:params) { { start_time: '6:00', end_time: '9:00', days: days, court_ids: [court_1.id, court_2.id] } }
        it 'renders conflicting prices' do
          expect { subject }.not_to change { price.reload.attributes }
          is_expected.to be_unprocessable
          expect(conflicting_prices).to match_array [price_1.id, price_2.id]
        end
      end
    end

    context 'with invalid params' do
      # error: end time < start_time
      let(:params) { { start_time: '12:00', end_time: '10:00' } }
      it 'does not work' do
        expect { subject }.not_to change { price.reload.attributes }
        is_expected.to be_unprocessable
        expect(conflicting_prices).to be_blank
      end
    end

  end

  describe '#destroy' do
    subject { delete :destroy, format: :json, venue_id: venue.id, id: price.id }
    let!(:court) { create :court, :with_prices, venue: venue}
    let!(:price) { court.prices.first }
    it 'works' do
      expect { subject }.to change { venue.prices.reload.uniq.size }.by(-1)
      is_expected.to be_success
    end
  end

end
