require "rails_helper"

RSpec.describe ReservationsController, type: :controller do
  describe "#create" do
    let(:company) { create :company }
    let(:admin) { create :admin, company: company }
    let!(:venue) { create :venue, :with_courts, court_count: 1, company: company }
    let(:court) { venue.courts.first }
    let(:params) {
      {
        reservations: {
          1 => FactoryGirl.attributes_for(:reservation, court: court).merge({court_id: court.id})
        },
        venue_id: venue.id,
        user: user,
        reservation: {
          'note': 'test reservation'
        }
      }
    }

    before do
      sign_in(admin)
    end

    after(:each) do
      ActionMailer::Base.deliveries.clear
    end

    context "with new user" do
      let!(:user) { FactoryGirl.attributes_for(:user, :unconfirmed) }

      it "should create reservation and user" do
        expect{post :create, params}.to change{Reservation.count}.by(1)
          .and change{User.count}.by(1)
          .and change{ActionMailer::Base.deliveries.count}.by(2)
      end

      it_behaves_like "loggable activity", 'reservation_created' do
        subject { post :create, params }
      end
    end

    context "with existing user" do
      let!(:existing_user) { create :user }
      let!(:user) {
        FactoryGirl.attributes_for(:user, :unconfirmed)
                  .merge({email: existing_user.email})
      }

      context "with user details and existing email" do
        it "should create reservation" do
          expect {post :create, params}.to change{Reservation.count}.by(1)
            .and change{User.count}.by(0)
            .and change{ActionMailer::Base.deliveries.count}.by(1)
        end

        it_behaves_like "loggable activity", 'reservation_created' do
          subject { post :create, params }
        end
      end

      context "with user id" do
        let!(:user) { {user_id: existing_user.id} }

        it "should create reservation" do
          expect {post :create, params}.to change{Reservation.count}.by(1)
            .and change{User.count}.by(0)
            .and change{ActionMailer::Base.deliveries.count}.by(1)
        end

        it_behaves_like "loggable activity", 'reservation_created' do
          subject { post :create, params }
        end
      end
    end
  end

  describe "#make_copy" do
    let(:company) { create :company }
    let(:admin) { create :admin, company: company }
    let(:membership) { create :membership }
    let(:timezone) { membership.venue.timezone }
    let(:user) { membership.user }
    let!(:reservation) do
      create :reservation,
             reselling: true,
             booking_type: :membership,
             membership: membership,
             user: user,
             court: membership.venue.courts.first,
             inactive: false,
             payment_type: :paid,
             is_paid: true,
             billing_phase: Reservation.billing_phases[:billed],
             price: 15,
             amount_paid: 15,
             charge_id: 'charge-id',
             initial_membership_id: membership.id,
             note: 'nice poem'
    end

    let(:params) do
      Time.use_zone(timezone) do
        {
          venue_id: membership.venue.id,
          id: reservation.id,
          reservation: {
            start_time: TimeSanitizer.strftime(reservation.start_time.advance(hours: 2), :time),
            end_time: TimeSanitizer.strftime(reservation.end_time.advance(hours: 2), :time),
            date: TimeSanitizer.strftime(reservation.start_time, :date),
            court_id: membership.venue.courts.last.id
          }
        }
      end
    end

    context 'valid params' do
      subject { put :make_copy, params }
      before do
        sign_in(admin)
      end

      it 'creates new reservation' do
        is_expected.to be_success
        expect(Reservation.count).to eql 2
      end

      it 'copies data from original reservation' do
        is_expected.to be_success

        new_reservation = Reservation.last
        expect(new_reservation.id).not_to eql reservation.id
        expect(new_reservation.user).to eql reservation.user
        expect(new_reservation.price).to eql reservation.price
        expect(new_reservation.note).to eql reservation.note
      end

      it 'moves new reservation to requested time and court' do
        is_expected.to be_success

        new_reservation = Reservation.last
        expect(new_reservation.id).not_to eql reservation.id
        expect(new_reservation.start_time).to eql reservation.start_time.advance(hours: 2)
        expect(new_reservation.end_time).to eql reservation.end_time.advance(hours: 2)
        expect(new_reservation.court).to eql membership.venue.courts.last
      end

      it 'sets admin booking type' do
        is_expected.to be_success

        new_reservation = Reservation.last
        expect(new_reservation.id).not_to eql reservation.id
        expect(new_reservation.booking_type).to eql 'admin'
      end

      it 'resets payment status' do
        is_expected.to be_success

        new_reservation = Reservation.last
        expect(new_reservation.payment_type).to eql 'unpaid'
        expect(new_reservation.is_paid).to be_falsey
        expect(new_reservation.billing_phase).to eq('not_billed')
        expect(new_reservation.amount_paid).to eq 0
        expect(new_reservation.charge_id).to eq nil
      end

      it 'resets membership, reselling and resold status' do
        is_expected.to be_success

        new_reservation = Reservation.last
        expect(new_reservation.membership).to eq nil
        expect(new_reservation.initial_membership_id).to eq nil
        expect(new_reservation.reselling).to be_falsey
      end

      it_behaves_like "loggable activity", "reservation_created"
    end

    context 'invalid params' do
      before do
        Time.use_zone(membership.venue.timezone) do # so that time values in params are correct
          params[:reservation][:start_time] = TimeSanitizer.strftime(reservation.start_time, :time)
          params[:reservation][:end_time] = TimeSanitizer.strftime(reservation.end_time, :time)
          params[:reservation][:court_id] = reservation.court.id

          sign_in(admin)
          put :make_copy, params
        end
      end
      it 'returns error' do
        expect(response.status).to eql 422

        error_message = I18n.t('activerecord.attributes.reservation.overlapping_reservation') +
                        ' ' +
                        I18n.t('errors.reservation.overlapping', user_name:  reservation.user.full_name.humanize)

        response_body = JSON.parse(response.body.to_s)
        expect(response_body['errors']['0'].any?).to be_truthy
        expect(response_body['errors']['0']).to include(error_message)
      end
    end
  end
end
