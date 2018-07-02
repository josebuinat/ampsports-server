require 'rails_helper'

describe Admin::Venues::Coaches::SalaryRatesController, type: :controller do
  render_views
  let!(:admin) { create :admin, :with_company }
  let!(:company) { admin.company }
  let!(:venue) { create :venue, company: company }
  let!(:coach) { create :coach, company: company, level: :manager }
  let(:salary_rates_scope) { coach.salary_rates.for_venue(venue) }

  before { sign_in_for_api_with admin }

  describe '#index' do
    subject{ get :index, venue_id: venue.id, coach_id: coach.id, **params }

    let(:params) do
      {
        sport: 'tennis',
        date: salary_rate1.start_time.to_s(:date)
      }
    end

    let(:salary_rate_ids) { json['salary_rates'].map { |x| x['id'] } }

    let!(:salary_rate1) { create :coach_salary_rate, coach: coach, venue: venue }
    let!(:salary_rate2) do
      create :coach_salary_rate, coach: coach,
                                 venue: venue,
                                 start_time: salary_rate1.start_time.advance(hours: 2)
    end
    let!(:other_sport_salary_rate) do
      create :coach_salary_rate, coach: coach,
                                 venue: venue,
                                 sport_name: 'squash'
    end
    let!(:other_date_salary_rate) do
      create :coach_salary_rate, venue: venue,
                                 start_time: salary_rate1.start_time.advance(days: 1)
    end
    let!(:other_venue_salary_rate) { create :coach_salary_rate, coach: coach }

    it 'returns salary rates' do
      is_expected.to be_success

      expect(salary_rate_ids).to match_array [salary_rate1.id, salary_rate2.id]
    end
  end

  describe '#show' do
    subject{ get :show, venue_id: venue.id, coach_id: coach.id, id: salary_rate.id }

    let!(:salary_rate) { create :coach_salary_rate, coach: coach, venue: venue }

    it 'returns salary rate JSON' do
      is_expected.to be_success

      expect(json['id']).to eq salary_rate.id
    end
  end

  describe '#create' do
    subject{ post :create, venue_id: venue.id, coach_id: coach.id, **params }

    let(:salary_rate) { build :coach_salary_rate, venue: venue, coach: coach }
    let(:params) do
      {
        salary_rate: {
          rate: rate,
          sport_name: 'squash',
          weekdays: ['monday', 'wednesday'],
          start_time: salary_rate.start_time.to_s(:time),
          end_time: salary_rate.end_time.to_s(:time)
        }
      }
    end
    let(:rate) { 33.33 }
    let(:new_salary_rate) { salary_rates_scope.last }

    context 'with valid params' do
      it 'creates salary rate' do
        expect{ subject }.to change{ salary_rates_scope.count }.by(1)
        is_expected.to be_created
        expect(new_salary_rate.start_minute_of_a_day).to eq salary_rate.start_minute_of_a_day
        expect(new_salary_rate.start_time).to eq salary_rate.start_time
        expect(new_salary_rate.end_time).to eq salary_rate.end_time
        expect(new_salary_rate.sport_name).to eq 'squash'
        expect(new_salary_rate.weekdays).to eq [:monday, :wednesday]
      end
    end

    context 'with invalid params' do
      let(:rate) { '' }

      it 'does not create salary rate' do
        expect{ subject }.not_to change{ salary_rates_scope.count }
        is_expected.to be_unprocessable
      end
    end
  end

  describe '#update' do
    subject{ patch :update, venue_id: venue.id, coach_id: coach.id, id: salary_rate.id, **params }

    let!(:salary_rate) { create :coach_salary_rate, venue: venue, coach: coach }
    let!(:start_time) { salary_rate.start_time.advance(hours: 1) }
    let(:params) do
      {
        salary_rate: {
          rate: rate,
          sport_name: 'squash',
          weekdays: ['monday', 'wednesday'],
          start_time: start_time.to_s(:time),
          end_time: start_time.advance(hours: 3).to_s(:time)
        }
      }
    end
    let(:rate) { 44.44 }

    context 'with valid params' do
      it 'updates salary rate' do
        expect{ subject }
          .to change{ salary_rate.reload.rate }.to(rate)
          .and change{ salary_rate.reload.start_time }.to(start_time)
          .and change{ salary_rate.reload.sport_name }.to('squash')
          .and change{ salary_rate.reload.weekdays }.to([:monday, :wednesday])

        is_expected.to be_success
      end
    end

    context 'with invalid params' do
      let(:rate) { '' }

      it 'does not update salary_rate' do
        expect{ subject }.not_to change{ salary_rate.reload.updated_at }
        is_expected.to be_unprocessable
      end
    end
  end

  describe '#destroy' do
    subject { delete :destroy, venue_id: venue.id, coach_id: coach.id, id: salary_rate.id }
    let!(:salary_rate) { create :coach_salary_rate, venue: venue, coach: coach }

    it 'deletes salary rate' do
      expect { subject }.to change { salary_rates_scope.count }.by(-1)
      is_expected.to be_success
      expect(json).to eq [salary_rate.id]
    end
  end

  describe '#destroy_many' do
    subject{ delete :destroy_many, venue_id: venue.id, coach_id: coach.id, **params }

    let!(:salary_rate1) { create :coach_salary_rate, coach: coach, venue: venue }
    let!(:salary_rate2) do
      create :coach_salary_rate, coach: coach,
                                 venue: venue,
                                 start_time: salary_rate1.start_time.advance(hours: 2)
    end
    let!(:other_salary_rate) { create :coach_salary_rate, coach: coach }

    let(:params) { { salary_rate_ids: [salary_rate1.id, salary_rate2.id] } }

    it 'deletes salary rates' do
      expect{ subject }.to change{ salary_rates_scope.count }.by(-2)

      is_expected.to be_success
      expect(json).to eq [salary_rate1.id, salary_rate2.id]
    end
  end
end

