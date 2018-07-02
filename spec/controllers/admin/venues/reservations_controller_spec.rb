require 'rails_helper'
require 'stripe_mock'

describe Admin::Venues::ReservationsController, type: :controller do
  render_views

  let!(:company) { create :company }
  let!(:venue) { create :venue, :with_courts, company: company, court_count: 1 }
  let(:court) { venue.courts.first }
  let(:current_admin) { create :admin, company: company }
  before { sign_in_for_api_with current_admin }

  let(:body) { JSON.parse response.body }

  describe "#create" do
    let(:reservations_param) do
      attributes_for = attributes_for(:reservation)
      [attributes_for.merge({
        court_id: court.id,
        start_tact: attributes_for[:start_time].strftime('%H:%M'),
        end_tact: attributes_for[:end_time].strftime('%H:%M'),
        date: attributes_for[:start_time].strftime('%d/%m/%Y'),
        coach_ids: [coach_id]
      })]
    end
    let(:meta_param) do
      { note: 'test reservation' }
    end
    let!(:params) do
      { reservations: reservations_param,
        user: user_param,
        participant_ids: participants_param,
        meta: meta_param,
      }
    end
    let(:created_reservation) { venue.reservations.last }
    let(:participants_param) { nil }
    let(:coach_id) { nil }
    let(:created_reservation) { venue.reservations.last }

    subject { post :create, params.merge(venue_id: venue.id, format: :json) }

    context "with new user" do
      context 'with valid params' do
        let(:user_param) { attributes_for(:user, :unconfirmed).merge(type: 'User') }
        let(:created_user) { User.last }
        it "creates reservation and user" do
          expect{ subject }.to change { Reservation.count }.by(1)
                           .and change { User.count }.by(1)
                           .and do_not_change { Guest.count }
                           .and change { ActionMailer::Base.deliveries.count }.by(2)

          expect(created_reservation.user).to eq created_user
          is_expected.to be_created
        end

        it 'adds user to the venue' do
          expect { subject }.to change { venue.users.count }.by(1)
          expect(venue.users).to include created_user
        end

        it_behaves_like "loggable activity", "reservation_created"
      end

      context 'with invalid params' do
        let(:user_param) { { first_name: 'Danny', last_name: 'Horse', type: 'User' } }

        it 'does not create reservation and user' do
          expect { subject }.to do_not_change { Reservation.count }.and do_not_change { User.count }
          is_expected.to be_unprocessable
        end
      end

      context 'when user is existing in another venue' do
        let!(:existing_user) { create :user, :with_venues }
        let(:user_param) { { email: existing_user.email, first_name: 'completely-new-name', type: 'User' } }

        it 'creates a reservation, but not a user' do
          expect { subject }.to change { Reservation.count }.by(1)
                            .and do_not_change { User.count }
                            .and do_not_change { Guest.count }

          is_expected.to be_created
        end

        it 'connects user to the venue' do
          expect { subject }.to change { venue.users.count }.by(1)
          expect(venue.users).to include existing_user
        end

        it 'does not change existing user attributes' do
          # in user_params we specified new first_name, but this action shall not
          # update existing users attributes. Very debatable, as hacker can create
          # 1kk users with many possible emails and set their info to wrong one,
          # e.g. full name = "Fart pooper", which will be impossible to change for venues
          expect { subject }.to_not change { existing_user.reload.attributes }
        end
      end
    end

    context "with existing user" do
      let!(:some_other_venue) { create :venue, :searchable, company: company }
      let!(:existing_user) { create(:user, venues: [some_other_venue]) }

      let(:user_param) { { type: 'User', id: existing_user.id } }

      it "creates reservation" do
        expect { subject }.to change { Reservation.count }.by(1)
                          .and do_not_change { User.count }
                          .and do_not_change { Guest.count }
                          .and change { ActionMailer::Base.deliveries.count }.by(1)

        is_expected.to be_success
      end

      it 'adds user to the venue' do
        expect { subject }.to change { venue.users.count }.by(1)
        expect(venue.users).to include existing_user
      end

      context "with participant users" do
        let!(:participant_user) { create(:user, venues: [some_other_venue]) }
        let(:participants_param) { [participant_user.id] }

        it 'adds participants to the reservation' do
          is_expected.to be_success
          expect(Reservation.last.participants).to include participant_user
        end

        it 'adds participants to the venue' do
          expect { subject }.to change { venue.users.count }.by(2)
          expect(venue.users).to include participant_user
        end
      end
    end

    context "with existing group" do
      let!(:existing_group) { create :group, venue: venue }

      let(:user_param) { { type: 'Group', id: existing_group.id } }

      it{ is_expected.to be_success }

      it "creates group reservation" do
        expect { subject }.to change { Reservation.count }.by(1)
                          .and do_not_change { User.count }
                          .and do_not_change { Guest.count }
                          .and change { ActionMailer::Base.deliveries.count }.by(1)

        is_expected.to be_success
        expect(Reservation.last.user).to eq existing_group
      end
    end

    context 'with new guest' do
      let(:user_param) { { type: 'Guest', full_name: 'Danny Horton' } }
      let(:created_guest) { Guest.last }
      it "creates reservation and guest" do
        expect{ subject }.to change { Reservation.count }.by(1)
                         .and change { Guest.count }.by(1)
                         .and do_not_change { User.count }

        expect(created_reservation.user).to eq created_guest
        is_expected.to be_success
      end

      it 'does not add guest to the venue' do
        expect { subject }.not_to change { venue.users.count }
      end
    end

    context 'with coach' do
      let!(:existing_user) { create(:user, venues: [venue]) }
      let(:user_param) { { type: 'User', id: existing_user.id } }
      let!(:coach) { create :coach, :available, company: company, for_court: court }
      let(:coach_id) { coach.id }
      let(:start_time) { in_venue_tz { Time.current.advance(days: 1).at_noon } }

      it "creates reservation with assigned coach" do
        expect { subject }.to change { venue.reservations.count }.by(1)

        is_expected.to be_success
        expect(created_reservation.coaches).to include coach
      end
    end
  end

  describe '#update' do
    subject { put :update, format: :json, **params }

    let(:user) { create :user, venues: [venue] }
    let!(:reservation) { create :reservation, court: venue.courts.first, user: user }
    let(:start_time) do
      in_venue_tz do
        Time.current.advance(weeks: 1).at_noon
      end
    end
    let(:params) do
      {
        id: reservation.id,
        venue_id: venue.id,
        reservation: reservation_params
      }
    end
    let(:reservation_params) do
      {
        paid_in_full: paid_in_full,
        game_pass_id: game_pass_id,
        price: price,
        amount_paid: amount_paid,
        court_id: court_id,
        user_id: reservation.user_id,
        date: start_time.to_s(:date),
        start_tact: start_time.to_s(:time),
        end_tact: start_time.advance(hours: 1).to_s(:time),
        note: 'updated reservation',
      }
    end
    let(:court_id) { reservation.court_id }
    let(:paid_in_full) { false }
    let(:game_pass_id) { nil }
    let(:amount_paid) { 22.22 }
    let(:price) { 33.33 }

    it 'updates price' do
      expect{ subject }.to change{ reservation.reload.price }.to(33.33)
      is_expected.to be_success
    end

    it 'updates amount paid and changes payment type' do
      expect{ subject }.to change{ reservation.reload.payment_type }.to('semi_paid')
                       .and change{ reservation.reload.amount_paid }.to(amount_paid)
      is_expected.to be_success
    end

    it 'updates timings' do
      is_expected.to be_success
      reservation.reload
      expect(reservation.start_time).to eq start_time
      expect(reservation.end_time).to eq start_time.advance(hours: 1)
    end

    context 'when assigning participants' do
      let!(:participant_1) { create :user }
      let!(:participant_2) { create :user }

      let(:reservation_params) do
        { participant_connections_attributes: [
          { user_id: participant_1.id, price: 10 },
          { user_id: participant_2.id, price: 10 },
        ], override_should_send_emails: override_should_send_emails }
      end
      let(:override_should_send_emails) { nil }

      it 'mails to them' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(2)
      end

      context 'with emails turned off' do
        let(:override_should_send_emails) { false }

        it 'mails no one' do
          expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end

    context 'when removing coaches' do
      let!(:coach) { create :coach, :available, for_court: venue.courts.first }
      let!(:reservation) { create :reservation, court: venue.courts.first, user: user, coaches: [coach] }
      # We want to test/ensure that order of keys is not important. Problem:
      # coach_ids will make transactions right away; if override_should_send_emails is assigned AFTER coach_ids,
      # then override_should_send_emails value would be `nil` for all operations inside coach_connections
      let(:reservation_params) { { coach_ids: [], override_should_send_emails: override_should_send_emails } }
      let(:override_should_send_emails) { nil }

      it 'mails to the coach' do
        expect { subject }.to change{ ActionMailer::Base.deliveries.count }.by(1)
      end

      context 'with email flag turned off' do
        let(:override_should_send_emails) { false }

        it 'sends no email' do
          expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end

    context 'when changing court' do
      let(:other_court) { create :court, :with_prices, venue: venue }
      let(:court_id) { other_court.id }

      it 'updates court' do
        expect{ subject }.to change{ reservation.reload.court_id }.to(court_id)
        is_expected.to be_success
      end
    end

    context 'when marking reservation as paid' do
      context 'with a paid_in_full' do
        let(:paid_in_full) { true }

        it 'marks reservation as paid' do
          expect{ subject }.to change{ reservation.reload.paid? }.to(true)
                           .and change{ reservation.reload.amount_paid }.to(33.33)

          is_expected.to be_success
        end
      end

      context 'with a game pass' do
        let!(:game_pass) { create :game_pass, :available, venue: venue, user: user }
        let(:game_pass_id) { game_pass.id }

        it 'marks reservation as paid and uses game pass charges' do
          expect{ subject }.to change{ reservation.reload.paid? }.to(true)
                           .and change{ reservation.reload.amount_paid }.to(33.33)
                           .and change{ reservation.reload.game_pass_id }.to(game_pass_id)
                           .and change{ game_pass.reload.remaining_charges }.by(-1.0)

          is_expected.to be_success
        end

        context 'when amount_paid is specified' do
          let(:amount_paid) { price }

          it 'ignores it and uses game pass (real bug)' do
            expect { subject }.to change { reservation.reload.paid? }.to(true)
                              .and change { game_pass.reload.remaining_charges }.by(-1.0)
          end
        end
      end
    end

    context 'when reservation is already paid' do
      let(:price) { 100 }
      let(:reservation) { create :reservation, court: venue.courts.first, user: user, price: 30, amount_paid: 30 }
      # 'cos every company needs the god
      let!(:other_admin) { create :admin, company: company, level: :god }
      let(:current_admin) { create :admin, company: company, level: :cashier }
      # since we first of all log in, other_admin will be created after current one,
      # hence current admin will be god and there's no way around this
      before { current_admin.update_attribute :level, :cashier }

      it 'cannot do that' do
        expect { subject }.not_to change { reservation.reload.price }
        is_expected.to be_forbidden
      end

      context 'with permission' do
        # have to generate that permissions first
        before do
          current_admin.cashier_permissions.merge(
            modify_paid_reservations: [:edit],
          ).each do |key, values|
            values.each do |value|
              current_admin.user_permissions.create! permission: key, value: value
            end
          end
        end

        it 'can do that' do
          expect { subject }.to change { reservation.reload.price }
          is_expected.to be_success
        end
      end
    end
  end

  describe '#toggle_resell_state' do
    subject { patch :toggle_resell_state, venue_id: venue.id, id: reservation.id, format: :json }

    let!(:reservation) do
      create :reservation, court: venue.courts.first, initial_membership_id: initial_membership_id, reselling: reselling
    end
    let(:initial_membership_id) { nil }
    let(:reselling) { false }

    context 'when already resold' do
      let(:initial_membership) { create :membership, venue: venue }
      let(:initial_membership_id) { initial_membership.id }

      before do
        expect(SegmentAnalytics).not_to receive(:admin_resell)
        expect(SegmentAnalytics).not_to receive(:withdraw_resell_booking)
      end

      it 'does not work' do
        expect { subject }.not_to change { reservation.reload.attributes }
        is_expected.to be_unprocessable
      end
    end

    context 'when reselling' do
      let(:reselling) { true }

      before do
        expect(SegmentAnalytics).to receive(:admin_resell).with(reservation, current_admin)
      end

      it 'cancels reselling' do
        expect { subject }.to change { reservation.reload.reselling }.from(true).to(false)
      end

      it_behaves_like "loggable activity", "reservation_updated"
    end

    context 'when not reselling' do
      before do
        expect(SegmentAnalytics).to receive(:withdraw_resell_booking).with(reservation, current_admin)
      end

      it 'puts on resell' do
        expect { subject }.to change { reservation.reload.reselling }.from(false).to(true)
      end

      it_behaves_like "loggable activity", "reservation_updated"
    end
  end

  describe '#resell_to_user' do
    subject { patch :resell_to_user, venue_id: venue.id,
      id: reservation.id, user: { type: 'User', id: new_owner.id } }
    let!(:membership) { create :membership, venue: venue }
    let!(:reservation) { create :reservation, court: venue.courts.first, reselling: true, membership: membership }
    let!(:new_owner) { create :user, venues: [venue] }

    it 'works' do
      expect { subject }.to change { reservation.reload.user }.to(new_owner)
      is_expected.to be_success
    end
  end

  describe '#destroy' do
    subject { delete :destroy, venue_id: venue.id, id: reservation.id, format: :json, skip_refund: skip_refund }

    let(:skip_refund) { false }
    let!(:user) { create :user, venues: [venue] }
    let!(:reservation) { create :reservation, court: venue.courts.first }

    before do
      StripeMock.start
      reservation.update_attribute(:charge_id, create_charge.id)
    end
    after { StripeMock.stop }

    it 'cancels reservation with refund' do
      expect{ subject }.to change{ Reservation.cancelled.count }.by(1)
      expect(Reservation.cancelled.find(reservation.id)).to be_refunded
    end

    context 'with skip refund param set to true' do
      let(:skip_refund) { true }

      it 'cancels reservation without refund' do
        expect{ subject }.to change{ Reservation.cancelled.count }.by(1)
        expect(Reservation.cancelled.find(reservation.id)).not_to be_refunded
      end
    end
  end

  describe '#mark_salary_paid_many' do
    subject { patch :mark_salary_paid_many, venue_id: venue.id,
                                            reservation_ids: reservation_ids,
                                            coach_id: coach.id }

    let!(:coach) { create :coach, :available, company: company, for_court: court }
    let(:reservation1) { create :reservation, court: venue.courts.first, coaches: [coach] }
    let(:reservation2) { create :reservation, court: venue.courts.first,
                                              coaches: [coach],
                                              start_time: reservation1.end_time }
    let(:reservation_ids) { [reservation1.id, reservation2.id] }

    it 'marks them' do
      expect{ subject }.to change{ reservation1.reload.coach_salary_paid(coach) }.to(true)
      is_expected.to be_success

      expect(json).to match_array reservation_ids
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
                          destination: user.stripe_id,
                          description: "Charge for test.user@test.com")
  end
end
