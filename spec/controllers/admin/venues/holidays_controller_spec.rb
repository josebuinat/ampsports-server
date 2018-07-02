require 'rails_helper'

describe Admin::Venues::HolidaysController, type: :controller do
  render_views

  let!(:company) { create :company }
  let!(:venue) { create :venue, company: company }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }

  let(:body) { JSON.parse response.body }

  describe '#index' do
    subject { get :index, format: :json, venue_id: venue.id }
    let(:holiday_ids) { body['holidays'].map { |x| x['id'] } }
    let!(:related_court) { create :court, venue: venue }
    let!(:unrelated_court) { create :court }
    let!(:related_holiday) { create :holiday, courts: [related_court] }
    let!(:unrelated_holiday) { create :holiday, courts: [unrelated_court] }

    it 'works' do
      is_expected.to be_success
      expect(holiday_ids).to eq [related_holiday.id]
    end
  end

  describe '#show' do
    subject { get :show, format: :json, venue_id: venue.id, id: holiday.id }
    let!(:court) { create :court, venue: venue }
    let!(:holiday) { create :holiday, courts: [court] }
    it { is_expected.to be_success }
  end

  describe '#create' do
    subject { post :create, format: :json, venue_id: venue.id, holiday: params }
    let!(:court) { create :court, venue: venue }
    let(:conflicting_reservations) { body['conflicting_reservations'] }
    context 'with valid params' do
      let(:params) do
        { start_time: 1.day.since.strftime('%d/%m/%Y %H:%M'),
          end_time: 3.days.since.strftime('%d/%m/%Y %H:%M'),
          court_ids: [court.id] }
      end

      it 'creates a holiday' do
        expect { subject }.to change { venue.holidays.count }.by(1)
        is_expected.to be_created
        expect(conflicting_reservations).to be_blank
      end

      context 'with conflicting reservations' do
        let(:start_time) { in_venue_tz { 2.days.since.at_noon } }
        let!(:reservation_1) { create :reservation,
                                      start_time: start_time.change(hour: 12, minute: 0),
                                      end_time: start_time.change(hour: 14, minute: 0),
                                      court: court
        }
        let!(:reservation_2) { create :reservation,
                                      start_time: start_time.change(hour: 15, minute: 0),
                                      end_time: start_time.change(hour: 16, minute: 0),
                                      court: court
        }

        it 'renders conflicting reservation' do
          is_expected.to be_created
          expect(conflicting_reservations.map { |x| x['id'] }).
            to match_array([reservation_1.id, reservation_2.id])
        end

      end
    end

    context 'with invalid params' do
      # error: end time < start_time
      let(:params) do
        { start_time: 2.day.since.strftime('%d/%m/%Y %H:%M'),
          end_time: 1.days.since.strftime('%d/%m/%Y %H:%M'),
          court_ids: [court.id] }
      end
      it 'does not work' do
        expect { subject }.not_to change { venue.holidays.count }
        is_expected.to be_unprocessable
      end
    end
  end

  describe '#update' do
    subject { patch :update, format: :json, venue_id: venue.id, id: holiday.id, holiday: params }
    let!(:court) { create :court, venue: venue }
    let!(:new_court) { create :court, venue: venue }
    let!(:holiday) { create :holiday, courts: [court] }
    context 'with valid params' do
      let(:params) { { court_ids: [court.id, new_court.id] } }
      it 'works' do
        # for some reason it requires reload both holiday and association to have a correct result
        expect { subject }.to change { holiday.reload.courts.reload }.from([court]).to([court, new_court])
        is_expected.to be_success
      end
    end

    context 'with invalid params' do
      let(:params) do
        { start_time: 1.day.since.strftime('%d/%m/%Y %H:%M'),
          end_time: 1.day.ago.strftime('%d/%m/%Y %H:%M') }
      end
      it 'does not work' do
        expect { subject }.not_to change { holiday.reload.attributes }
        is_expected.to be_unprocessable
      end
    end
  end

  describe '#destroy' do
    subject { delete :destroy, format: :json, venue_id: venue.id, id: holiday.id }
    let!(:holiday) { create :holiday, courts: [court] }
    context 'with legit holiday' do
      let!(:court) { create :court, venue: venue }
      it 'works' do
        expect { subject }.to change { venue.holidays.count }.by(-1)
        is_expected.to be_success
      end
    end

    context 'with wrong holiday' do
      let!(:court) { create :court }
      it 'does not work' do
        expect { subject }.not_to change { venue.holidays.count }
        is_expected.to be_not_found
      end
    end
  end

  describe '#destroy_many' do
    subject { delete :destroy_many, format: :json, venue_id: venue.id, holiday_ids: holiday_ids }
    let!(:court) { create :court, venue: venue }
    let!(:holiday_1) { create :holiday, courts: [court] }
    let!(:holiday_2) { create :holiday, courts: [court] }
    let(:holiday_ids) { [holiday_1.id, holiday_2.id] }
    it 'works' do
      expect { subject }.to change { venue.holidays.count }.by(-2)
      is_expected.to be_success
    end
  end
end
