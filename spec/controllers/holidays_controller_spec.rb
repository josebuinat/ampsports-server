require 'rails_helper'

describe HolidaysController, type: :controller do
  let(:court) { create(:court) }
  let(:timezone) { court.venue.timezone }
  let(:params) do
    Time.use_zone(timezone) do
      {
        venue_id: court.venue.id,
        holiday: {
          court_ids: [court.id],
          start_date: DateTime.tomorrow.to_s,
          end_date: (DateTime.tomorrow + 1.day).to_s,
          start_time: DateTime.current.change(hour: 6, minute: 0).strftime('%H:%M'),
          end_time: DateTime.current.change(hour: 20, minute: 0).strftime('%H:%M')
        }
      }
    end
  end

  describe 'POST create' do
    subject { post :create, params }

    context 'without conflicting reservation' do
      it 'responds with success' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'creates holiday' do
        expect { subject }.to change(Holiday, :count).by(1)
      end

      it "doesn't have conflicting reservations" do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['conflicting'].count).to eq(0)
      end
    end

    context 'with conflicting reservations' do
      let(:start_time) { Time.use_zone(timezone) { DateTime.tomorrow.at_noon } }

      before do
        Time.use_zone(timezone) do
          @reservation = create(:reservation,
                 start_time: start_time.change(hour: 12, minute: 0),
                 end_time: start_time.change(hour: 14, minute: 0),
                 court: court
          )
          create(:reservation,
                 start_time: start_time.change(hour: 15, minute: 0),
                 end_time: start_time.change(hour: 16, minute: 0),
                 court: court
          )
        end
      end

      let(:reservation) { @reservation }

      it 'responds with success' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'has conflicting reservation' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['conflicting'].map { |x| x['id'] }).to match_array Reservation.pluck(:id)
      end

      it 'finds all conflicting reservations' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['conflicting'].count).to eq(2)
      end

      context 'with cancel reservations' do
        subject do
          post :create, params
          post :handle_conflicting, { holiday_id: Holiday.first.id, cancel_conflicting: true }
        end

        it 'responds with success' do
          is_expected.to be_success
        end

        it 'cancels reservations' do
          subject
          expect(reservation.reload.inactive?).to be_truthy
        end

        it_behaves_like "loggable activity", "reservation_cancelled"
      end

      context 'with keep reservations' do
        before do
          subject
          post :handle_conflicting, { holiday_id: Holiday.first.id, cancel_conflicting: false }
          reservation.reload
        end

        it 'responds with success' do
          expect(response).to have_http_status(200)
        end

        it 'does not cancel reservations' do
          expect(reservation.inactive?).to be_falsey
        end
      end
    end
  end
end
