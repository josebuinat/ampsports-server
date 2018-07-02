require 'rails_helper'

describe Admin::Venues::Coaches::PriceRatesController, type: :controller do
  render_views
  let!(:admin) { create :admin, :with_company }
  let!(:company) { admin.company }
  let!(:venue) { create :venue, company: company }
  let(:coach) { create :coach, company: company, level: :manager }
  let(:price_rates_scope) { coach.price_rates.for_venue(venue) }

  before { sign_in_for_api_with admin }

  describe '#index' do
    subject{ get :index, venue_id: venue.id, coach_id: coach.id, **params }

    let(:params) do
      {
        sport: 'tennis',
        date: price_rate1.start_time.to_s(:date)
      }
    end

    let(:price_rate_ids) { json['price_rates'].map { |x| x['id'] } }

    let!(:price_rate1) { create :coach_price_rate, coach: coach, venue: venue }
    let!(:price_rate2) do
      create :coach_price_rate, coach: coach,
                                 venue: venue,
                                 start_time: price_rate1.start_time.advance(days: 1)
    end
    let!(:other_sport_price_rate) do
      create :coach_price_rate, coach: coach,
                                 venue: venue,
                                 sport_name: 'squash'
    end
    let!(:other_date_price_rate) do
      create :coach_price_rate, coach: coach,
                                 venue: venue,
                                 start_time: price_rate1.start_time.advance(weeks: 1)
    end
    let!(:other_venue_price_rate) { create :coach_price_rate, coach: coach }

    it 'returns price rates' do
      is_expected.to be_success

      expect(price_rate_ids).to match_array [price_rate1.id, price_rate2.id]
    end

    context 'when accessed by owner coach with base level' do
      let(:coach) { create :coach, company: company, level: :base }
      before { sign_in_for_api_with coach }

      it{ is_expected.to be_success }
    end

    context 'when accessed by other coach with base level' do
      let(:other_coach) { create :coach, company: company, level: :base }
      before { sign_in_for_api_with other_coach }

      it 'does not return price rates' do
        is_expected.to be_success

        expect(price_rate_ids).to eq []
      end
    end

    context 'when accessed by other coach with manager level' do
      let(:other_coach) { create :coach, company: company, level: :manager }
      before { sign_in_for_api_with other_coach }

      it{ is_expected.to be_success }
    end
  end


  describe '#show' do
    subject{ get :show, venue_id: venue.id, coach_id: coach.id, id: price_rate.id }

    let!(:price_rate) { create :coach_price_rate, coach: coach, venue: venue }

    it 'returns price rate JSON' do
      is_expected.to be_success

      expect(json['id']).to eq price_rate.id
    end

    context 'when accessed by owner coach with base level' do
      let(:coach) { create :coach, company: company, level: :base }
      before { sign_in_for_api_with coach }

      it{ is_expected.to be_success }
    end

    context 'when accessed by other coach with base level' do
      let(:other_coach) { create :coach, company: company, level: :base }
      before { sign_in_for_api_with other_coach }

      it{ is_expected.to be_not_found }
    end

    context 'when accessed by other coach with manager level' do
      let(:other_coach) { create :coach, company: company, level: :manager }
      before { sign_in_for_api_with other_coach }

      it{ is_expected.to be_success }
    end
  end

  describe '#create' do
    subject{ post :create, venue_id: venue.id, coach_id: coach.id, **params }

    let(:price_rate) { build :coach_price_rate, venue: venue, coach: coach }
    let(:params) do
      {
        price_rate: {
          rate: rate,
          sport_name: 'squash',
          start_time: in_venue_tz{ price_rate.start_time.in_time_zone.to_s(:date_time) },
          end_time: in_venue_tz{ price_rate.end_time.in_time_zone.to_s(:date_time) }
        }
      }
    end
    let(:rate) { 33.33 }
    let(:new_price_rate) { price_rates_scope.last }

    context 'with valid params' do
      it 'creates price rate' do
        expect{ subject }.to change{ price_rates_scope.count }.by(1)
        is_expected.to be_created
        expect(new_price_rate.start_time).to eq price_rate.start_time
        expect(new_price_rate.end_time).to eq price_rate.end_time
        expect(new_price_rate.sport_name).to eq 'squash'
      end
    end

    context 'with invalid params' do
      let(:rate) { '' }

      it 'does not create price rate' do
        expect{ subject }.not_to change{ price_rates_scope.count }
        is_expected.to be_unprocessable
      end
    end
  end

  describe '#create_many' do
    subject{ post :create_many, venue_id: venue.id, coach_id: coach.id, **params }

    let(:price_rate) { build :coach_price_rate, venue: venue, coach: coach }
    let(:start_time) { price_rate.start_time }
    let(:end_time) { price_rate.end_time }
    let(:second_end_time_param) { in_venue_tz{ end_time.advance(days: 1).in_time_zone.to_s(:date_time) } }
    let(:params) do
      {
        rate: 33.33,
        sport_name: 'squash',
        times: [
          {
            start_time: in_venue_tz{ start_time.in_time_zone.to_s(:date_time) },
            end_time: in_venue_tz{ end_time.in_time_zone.to_s(:date_time) }
          },
          {
            start_time: in_venue_tz{ start_time.advance(days: 1).in_time_zone.to_s(:date_time) },
            end_time: second_end_time_param
          }
        ]
      }
    end
    let(:new_price_rate) { price_rates_scope.last }

    context 'with valid params' do
      it 'creates price rate' do
        expect{ subject }.to change{ price_rates_scope.count }.by(2)
        is_expected.to be_created
        expect(new_price_rate.start_time).to eq start_time.advance(days: 1)
        expect(new_price_rate.end_time).to eq end_time.advance(days: 1)
        expect(new_price_rate.sport_name).to eq 'squash'
      end
    end

    context 'with invalid params' do
      let(:second_end_time_param) { '' }

      it 'does not create price rate' do
        expect{ subject }.not_to change{ price_rates_scope.count }
        is_expected.to be_unprocessable
      end
    end
  end

  describe '#update' do
    subject{ patch :update, venue_id: venue.id, coach_id: coach.id, id: price_rate.id, **params }

    let!(:price_rate) { create :coach_price_rate, venue: venue, coach: coach }
    let(:start_time) { price_rate.start_time.advance(days: 1) }
    let(:params) do
      {
        price_rate: {
          rate: rate,
          sport_name: 'squash',
          start_time: in_venue_tz{ start_time.in_time_zone.to_s(:date_time) },
          end_time: in_venue_tz{ start_time.in_time_zone.advance(hours: 3).to_s(:date_time) }
        }
      }
    end
    let(:rate) { 44.44 }

    context 'with valid params' do
      it 'updates price rate' do
        expect{ subject }
          .to change{ price_rate.reload.rate }.to(rate)
          .and change{ price_rate.reload.start_time }.to(start_time)
          .and change{ price_rate.reload.sport_name }.to('squash')

        is_expected.to be_success
      end
    end

    context 'with invalid params' do
      let(:rate) { '' }

      it 'does not update price_rate' do
        expect{ subject }.not_to change{ price_rate.reload.updated_at }
        is_expected.to be_unprocessable
      end
    end
  end

  describe '#destroy' do
    subject { delete :destroy, venue_id: venue.id, coach_id: coach.id, id: price_rate.id }
    let!(:price_rate) { create :coach_price_rate, venue: venue, coach: coach }

    it 'deletes price rate' do
      expect { subject }.to change { price_rates_scope.count }.by(-1)
      is_expected.to be_success
      expect(json).to eq [price_rate.id]
    end
  end

  describe '#destroy_many' do
    subject{ delete :destroy_many, venue_id: venue.id, coach_id: coach.id, **params }

    let!(:price_rate1) { create :coach_price_rate, coach: coach, venue: venue }
    let!(:price_rate2) do
      create :coach_price_rate, coach: coach,
                                 venue: venue,
                                 start_time: price_rate1.start_time.advance(hours: 2)
    end
    let!(:other_price_rate) { create :coach_price_rate, coach: coach }

    let(:params) { { price_rate_ids: [price_rate1.id, price_rate2.id] } }

    it 'deletes price rates' do
      expect{ subject }.to change{ price_rates_scope.count }.by(-2)

      is_expected.to be_success
      expect(json).to eq [price_rate1.id, price_rate2.id]
    end
  end
end

