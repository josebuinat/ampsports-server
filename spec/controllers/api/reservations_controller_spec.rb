require "rails_helper"
require 'stripe_mock'

describe API::ReservationsController, type: :controller do
  render_views
  let!(:membership) { create :membership }
  let!(:user) { membership.user }

  let(:auth_token) { 'superawesometoken' }

  describe '#index' do
    subject{ get :index }

    let(:venue) { create :venue, :with_courts }
    let!(:user) { create :user, venues: [venue] }
    let(:court1) { venue.courts.first }
    let(:court2) { venue.courts.second }

    let(:group) { create :group, venue: venue }
    let(:coach) { create :coach, :available, company: venue.company, for_court: court1 }
    let!(:group_reservation) { create :reservation, user: group, court: court1 }
    let!(:participation) { create :participation, user: user, reservation: group_reservation }
    let!(:coached_reservation) { create :reservation, user: user, court: court2, coaches: [coach] }
    let(:dates_of_lessons) { json['lessons_future']['dates'].map { |x| x['date'] } }
    let(:expected_dates_of_lessons) do
      Time.use_zone(venue.timezone) do
        Time.current.advance(weeks: 2).beginning_of_week.at_noon.strftime('%Y-%m-%d')
      end
    end
    before { sign_in_for_api_with user }

    it 'returns dates of lessons' do
      is_expected.to be_success

      expect(dates_of_lessons).to match_array [ expected_dates_of_lessons ]
    end
  end

  describe "POST #payment" do
    subject{ post :payment, reservation_id: reservation.id, **params }

    let(:venue) { create :venue, :searchable }
    let(:court) { create :court, :with_prices,
                                   venue: venue,
                                   sport_name: :tennis,
                                   duration_policy: :any_duration
    }
    let!(:reservation) { create :reservation,
                                  booking_type: :online,
                                  user: user,
                                  court: court,
                                  price: 20.0
    }

    context 'with card' do
      let(:params) { { card_token: stripe_helper.generate_card_token } }
      let(:stripe_helper) { StripeMock.create_test_helper }

      before { StripeMock.start }
      after { StripeMock.stop }

      it 'updates status and amount_paid' do
        expect{ subject }.to change{ reservation.reload.payment_type }.to("paid")
                         .and change{ reservation.reload.amount_paid }.to(20.0)
        is_expected.to be_success
      end

      it_behaves_like 'loggable activity', 'reservation_updated'

      context 'when invalid card' do
        let(:params) { { card_token: 'invalid' } }

        it 'returns error' do
          expect{ subject }.not_to change{ reservation.reload.payment_type }
          is_expected.to be_unprocessable
          expect(json['errors']).to include({ "payment" => [I18n.t('errors.reservation.card_payment_error')] })
        end
      end
    end

    context 'with game pass' do
      let(:params) { { game_pass_id: game_pass.id } }
      let(:game_pass) { create :game_pass, :available, user: user, venue: venue }

      it 'uses game pass and updates status' do
        expect{ subject }.to change{ reservation.reload.payment_type }.to("paid")
                         .and change{ game_pass.reload.remaining_charges }.by(-1.0)
                         .and change{ reservation.reload.game_pass_id }.to(game_pass.id)

        is_expected.to be_success
      end

      # won't work because of clear_changes_information in the #pay_with_game_pass callback
      #it_behaves_like 'loggable activity', 'reservation_updated'
    end

    context 'when can not determine payment method' do
      let(:params) { { } }

      it 'returns error' do
        is_expected.to be_unprocessable
        expect(json['errors']).to include({ "payment" => [I18n.t('errors.reservation.unknown_payment_method')] })
      end
    end
  end

  describe "GET resell" do
    before do
      request.headers.merge!({ "Authorization" => "Bearer #{auth_token}" })
      allow(AuthToken).to receive(:decode).and_return({ id: user.id })
    end

    subject { get(:resell, reservation_id: reservation.id) }

    it 'render error when record not found' do
      get(:resell, reservation_id: 'not real id')
      response_body = JSON.parse(response.body.to_s)
      expect(response.status).to eql 404
      expect(response_body['errors']).to eql [I18n.t('api.record_not_found')]
    end

    context 'not reselling' do
      context 'resellable' do
        let!(:reservation) { create :reservation,
                                    reselling: false,
                                    user: user,
                                    membership: membership
      }

        it 'puts reservation on resell' do
          subject
          expect(reservation.reload.reselling?).to be_truthy
          response_body = JSON.parse(response.body.to_s)
          expect(response.status).to eql 200
          expect(response_body['message']).to eql I18n.t('api.reservations.reservation_put_on_resell')
        end

        it_behaves_like 'loggable activity', 'reservation_updated'
      end

      context 'not resellable' do
        let!(:reservation) { create(:reservation, reselling: false, user: user) }

        it 'puts reservation on resell' do
          subject
          expect(reservation.reload.reselling?).not_to be_truthy
          response_body = JSON.parse(response.body.to_s)
          expect(response.status).to eql 422
          expect(response_body['errors']).to eql [I18n.t('api.reservations.not_eligible_request')]
        end
      end
    end

    context 'reselling' do
      let!(:reservation) { create :reservation,
                                  reselling: true,
                                  user: user,
                                  membership: membership
      }

      it 'withdraws reservation' do
        subject
        expect(reservation.reload.reselling?).to be_falsy
        response_body = JSON.parse(response.body.to_s)
        expect(response.status).to eql 200
        expect(response_body['message']).to eql I18n.t('api.reservations.reservation_was_withdrawn')
      end

      it_behaves_like 'loggable activity', 'reservation_updated'
    end

    context 'resold' do
      let!(:reservation) { create :reservation,
                                  reselling: true,
                                  user: user,
                                  membership: membership,
                                  initial_membership_id: 1
      }

      it 'withdraws reservation' do
        subject
        response_body = JSON.parse(response.body.to_s)
        expect(response.status).to eql 400
        expect(response_body['errors'].first).to eql I18n.t('api.reservations.reservation_already_resold')
      end
    end

  end

  describe "destroy" do
    let!(:another_membership) { create :membership }
    let!(:another_user) { another_membership.user }

    let!(:unpaid_reservation) { create :reservation,
                                       reselling: false,
                                       booking_type: :membership,
                                       membership: membership,
                                       user: user,
                                       court: membership.venue.courts.first,
                                       inactive: false
    }
    let!(:paid_reservation) { create :reservation,
                                     reselling: false,
                                     booking_type: :membership,
                                     membership: another_membership,
                                     user: another_user,
                                     court: another_membership.venue.courts.first,
                                     inactive: false,
                                     payment_type: :paid
    }

    context "with unpaid reservation" do
      before do
        request.headers.merge!({ "Authorization" => "Bearer #{auth_token}" })
        allow(AuthToken).to receive(:decode).and_return({ id: user.id })
      end

      it "makes reservation inactive and returns status code 200" do
        reservation_count = Reservation.count
        delete :destroy, id: unpaid_reservation.id

        expect(Reservation.count).to eql reservation_count - 1
        response_body = JSON.parse(response.body.to_s)
        expect(response.status).to eql 200
        expect(response_body['message']).to eql I18n.t('api.reservations.reservation_cancelled')
      end

      it "sends cancellation email" do
        expect { delete :destroy, id: unpaid_reservation.id }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it_behaves_like 'loggable activity', 'reservation_cancelled' do
        subject { delete :destroy, id: unpaid_reservation.id }
      end
    end

    context "with paid reservation" do
      before do
        request.headers.merge!({ "Authorization" => "Bearer #{auth_token}" })
        allow(AuthToken).to receive(:decode).and_return({ id: another_user.id })
        allow_any_instance_of(Stripe::ListObject).to receive(:create).with(anything).and_return(true)
      end

      it "makes reservation inactive and refunded" do
        reservation_count = Reservation.count
        VCR.use_cassette('stripe_refund') do
          Time.use_zone(paid_reservation.membership.venue.timezone) do
            paid_reservation.update_attributes!(charge_id: create_charge.id)
          end
          delete :destroy, id: paid_reservation.id
        end

        expect(paid_reservation.reload.refunded).to be_truthy
        expect(Reservation.count).to eql reservation_count - 1
      end

      it_behaves_like 'loggable activity', 'reservation_cancelled' do
        subject { delete :destroy, id: paid_reservation.id }
      end
    end

    context 'when reservation does not belong to user but he is a participant' do
      let!(:group) { create :group, venue: another_membership.venue }
      let!(:group_reservation) { create :reservation, user: group, court: another_membership.venue.courts.second }
      let!(:participation) { create :participation, user: user, reservation: group_reservation }

      subject{ delete :destroy, id: group_reservation.id }

      before do
        request.headers.merge!({ "Authorization" => "Bearer #{auth_token}" })
        allow(AuthToken).to receive(:decode).and_return({ id: user.id })
        allow_any_instance_of(Stripe::ListObject).to receive(:create).with(anything).and_return(true)
      end

      it "cancels participation" do
        expect{ subject }.to change { participation.reload.cancelled }.to(true)
                         .and change { group_reservation.reload.participation_for(user) }.to(nil)
        is_expected.to be_success
      end

      it_behaves_like 'loggable activity', 'participation_cancelled'
    end

    context 'reservation does not belong to user' do
      before do
        request.headers.merge!({ "Authorization" => "Bearer #{auth_token}" })
        allow(AuthToken).to receive(:decode).and_return({ id: user.id })
        allow_any_instance_of(Stripe::ListObject).to receive(:create).with(anything).and_return(true)
      end

      it "informs user that reservation is not cancellable" do
        reservation_count = Reservation.count
        VCR.use_cassette('stripe_refund') do
          paid_reservation.update_attributes(charge_id: create_charge.id)
          delete :destroy, id: paid_reservation.id
        end
        expect(response.body).to eql({"errors":{"0": I18n.t('api.reservations.reservation_not_cancelled')}}.to_json)
        expect(paid_reservation.reload.refunded).to be_falsey
        expect(Reservation.count).to eql reservation_count
      end
    end

    context "when wrong user is authorized" do
      before do
        allow_any_instance_of(Stripe::ListObject).to receive(:create).with(anything).and_return(true)
      end

      it "responds that you are not authorized to perform the action" do
        VCR.use_cassette('stripe_refund') do
          paid_reservation.update_attributes(charge_id: create_charge.id)
          delete :destroy, id: paid_reservation.id
        end

        expect(response.status).to eql 401
      end
    end

    context "when reservation is not cancelable" do
      before do
        hours_until_reservation = (paid_reservation.start_time - Time.current.utc) / 1.hour
        another_membership.venue.update_attribute(:cancellation_time, hours_until_reservation + 1 )
        request.headers.merge!({ "Authorization" => "Bearer #{auth_token}" })
        allow(AuthToken).to receive(:decode).and_return({ id: another_user.id })
        allow_any_instance_of(Stripe::ListObject).to receive(:create).with(anything).and_return(true)
      end

      it "informs user that reservation is not cancellable" do
        reservation_count = Reservation.count
        VCR.use_cassette('stripe_refund') do
          paid_reservation.update_attributes(charge_id: create_charge.id)
          delete :destroy, id: paid_reservation.id
        end
        expect(response.body).to eql({"errors":{"0": I18n.t('api.reservations.reservation_not_cancelled')}}.to_json)
        expect(paid_reservation.reload.refunded).to be_falsey
        expect(Reservation.count).to eql reservation_count
      end
    end
  end

  describe 'download' do
    let(:membership) { create :membership }
    let(:reservation) do
      Time.use_zone(membership.venue.timezone) do
        create(:reservation, reselling: false, user: user, membership: membership)
      end
    end

    it 'returns a file to download' do
      request.headers.merge!({ "Authorization" => "Bearer #{auth_token}" })
      allow(AuthToken).to receive(:decode).and_return({ id: reservation.user.id })
      get :download, reservation_id: reservation.id, format: :ics
      expect(response.body).to include("CALENDAR")
    end
  end

  def stripe_token
    card_info = {
      number: "4242424242424242",
      exp_month: 1,
      exp_year: 2018,
      cvc: 314
    }
    Stripe::Token.create(card: card_info)
  end

  def create_charge
    Stripe::Charge.create(amount: 2000,
                          currency: "usd",
                          source: stripe_token.id,
                          destination: another_user.stripe_id,
                          description: "Charge for test.user@test.com")
  end
end
