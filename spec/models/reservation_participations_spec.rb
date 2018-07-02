require "rails_helper"

describe ReservationParticipations do
  let(:admin) { create :admin }
  let!(:venue) { create :venue, :with_courts, court_counts: 1 }
  let!(:court) { venue.courts.first }
  let!(:group) { create :group, venue: venue }


  describe '#participations' do
    let!(:reservation) { create :reservation, user: group, court: court }
    let!(:participation) { create :participation, reservation: reservation }

    it 'returns participations' do
      expect(reservation.participations).to include(participation)
    end

    it 'updates counter cache' do
      expect(reservation.participations_count).to eq 1
    end
  end

  describe '#for_group?' do
    context 'reservation by group' do
      let!(:reservation) { create :reservation, user: group, court: court }

      it 'returns true' do
        expect(reservation.for_group?).to be_truthy
      end
    end

    context 'reservation by user' do
      let!(:reservation) { create :reservation }

      it 'returns false' do
        expect(reservation.for_group?).to be_falsey
      end
    end
  end

  context '#before_create :assign_zero_price' do
    describe '#assign_zero_price' do
      context 'reservation by group' do
        context 'owned by admin' do
          let!(:group) { create :group, venue: venue, owner: create(:admin) }
          let!(:reservation) { create :reservation, user: group, court: court }

          it 'returns true' do
            expect(reservation.for_admin_group?).to be_truthy
          end

          it 'sets price to zero' do
            expect(reservation.price).to eq 0
          end

          it 'sets paid status' do
            expect(reservation.is_paid).to be_truthy
            expect(reservation.payment_type).to eq 'paid'
          end
        end

        context 'owned by user' do
          let!(:reservation) { create :reservation, user: group, court: court }

          it 'returns false' do
            expect(reservation.for_admin_group?).to be_falsey
          end

          it 'does not change price to zero' do
            expect(reservation.price).to be > 0
          end

          it 'does not change unpaid status' do
            expect(reservation.is_paid).to be_falsey
            expect(reservation.payment_type).to eq 'unpaid'
          end
        end
      end

      context 'reservation by user' do
        let!(:reservation) { create :reservation, court: court }

        it 'returns false' do
          expect(reservation.for_admin_group?).to be_falsey
        end

        it 'does not change price to zero' do
          expect(reservation.price).to be > 0
        end

        it 'does not change unpaid status' do
          expect(reservation.is_paid).to be_falsey
          expect(reservation.payment_type).to eq 'unpaid'
        end
      end
    end
  end

  context 'before_create :assign_member_participants, if: :for_group?' do
    describe '#assign_member_participants' do
      context 'non seasonal group' do
        let!(:group) { create :group, venue: venue, owner: create(:admin) }
        let!(:member1) { create :group_member, group: group }
        let!(:member2) { create :group_member, group: group }
        let(:reservation) { create :reservation, user: group, court: court }

        it 'creates participations for reservation' do
          expect{ reservation }.to change { Participation.count }.by(2)
          expect(reservation.reload.participations_count).to eq 2
        end

        it 'creates participations with members users' do
          expect(reservation.participations.map(&:user)).to match_array([member1.user, member2.user])
        end
      end

      context 'seasonal group' do
        let!(:group) { create :group, venue: venue, priced_duration: :season }
        let!(:group_season) { create :group_season, group: group, current: true }
        let!(:paid_member) { create(:group_member, group: group).
                              tap { |member| member.subscriptions.last.mark_paid } }
        let!(:unpaid_member) { create :group_member, group: group }
        let(:reservation) { create :reservation, user: group, court: court }

        it 'creates participations with payment status based on subscription' do
          expect{ reservation }.to change { Participation.count }.by(2)
          participations = Participation.all.order(created_at: :desc, is_paid: :asc).limit(2)
          expect(participations.last.user).to eq paid_member.user
          expect(participations.first.user).to eq unpaid_member.user
        end
      end
    end
  end

  context 'after_save group mailers' do
    describe '#group_session_changed?' do
      context 'reservation by group' do
        let!(:reservation) { create :reservation, user: group, court: court }

        it 'notifies group if start_time changed' do
          expect(ReservationMailer).to receive(:reservation_updated).at_most(:twice).and_call_original

          reservation.update_attribute(:start_time, reservation.start_time + 30.minutes)
        end

        it 'notifies group if end_time changed' do
          expect(ReservationMailer).to receive(:reservation_updated).at_most(:twice).and_call_original

          reservation.update_attribute(:end_time, reservation.end_time + 30.minutes)
        end

        it 'notifies group if court_id changed' do
          expect(ReservationMailer).to receive(:reservation_updated).at_most(:twice).and_call_original

          reservation.update_attribute(:court_id, reservation.court_id + 1)
        end

        it 'calls cancel_participations if cancelled' do
          expect(CancellationMailer).to receive(:admin_cancellation_email).at_most(:twice).and_call_original

          reservation.cancel(admin)
        end
      end

      context 'reservation by user' do
        let!(:reservation) { create :reservation, court: court }

        it 'notifies user if start_time changed' do
          expect(ReservationMailer).to receive(:reservation_updated).at_most(:twice).and_call_original

          reservation.update_attribute(:start_time, reservation.start_time + 30.minutes)
        end

        it 'notifies user if end_time changed' do
          expect(ReservationMailer).to receive(:reservation_updated).at_most(:twice).and_call_original

          reservation.update_attribute(:end_time, reservation.end_time + 30.minutes)
        end

        it 'notifies user if court_id changed' do
          expect(ReservationMailer).to receive(:reservation_updated).at_most(:twice).and_call_original

          reservation.update_attribute(:court_id, reservation.court_id + 1)
        end
      end
    end

    describe 'when court is updated' do
      subject { reservation.update_attribute(:court_id, reservation.court_id + 1) }

      let!(:reservation) { create :reservation, user: group, court: court }

      context 'called for participants' do
        let!(:participation1) { create :participation, reservation: reservation }
        let!(:participation2) { create :participation, reservation: reservation }

        it 'calls mailer for each participant' do
          expect(ReservationMailer).to receive(:reservation_updated).
            with(reservation.user, reservation, instance_of(Hash)).at_most(:twice).and_call_original
          expect(ReservationMailer).to receive(:reservation_updated).
            with(participation1.user, reservation, instance_of(Hash)).at_most(:twice).and_call_original
          expect(ReservationMailer).to receive(:reservation_updated).
            with(participation2.user, reservation, instance_of(Hash)).at_most(:twice).and_call_original

          subject
        end
      end

      context 'send mail' do
        let!(:participation) { create :participation, reservation: reservation }

        it 'does not fail' do
          expect{ subject }.not_to raise_error
        end

        it 'sends mail' do
          expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(2)
        end

        it 'does not send mail if disabled' do
          participation.user.settings(:email_notifications).put(:reservation_updates, false)
          # email goes to group owner only
          expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end

      context 'reservation cancelled' do
        let!(:participation) { create :participation, reservation: reservation }

        it 'does not fail' do
          expect{ reservation.cancel(admin) }.not_to raise_error
        end

        it 'sends mail' do
          # cancellation mail to reservation owner and update mail to participant
          expect { reservation.cancel(admin) }.to change { ActionMailer::Base.deliveries.count }.by(2)
        end

        it 'does not send mail to user if disabled' do
          participation.user.settings(:email_notifications).put(:reservation_cancellations, false)
          expect { reservation.cancel(admin) }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end
    end
  end

  describe '#participation_price' do
    subject { reservation.participation_price }
    let!(:time) { in_venue_tz { Time.current.at_noon.advance(years: 1).change(month: 3) } }
    let!(:venue) { create :venue, :with_courts, court_count: 1, booking_ahead_limit: 700 }
    let!(:reservation) {
      create :reservation, user: group, court: venue.courts.first, start_time: time, end_time: time + 2.hours
    }

    context 'price per session' do
      let(:group) { create :group, venue: venue, priced_duration: :session }

      it 'returns calculated price' do
        is_expected.to eq group.participation_price
      end
    end

    context 'price per hour' do
      let(:group) { create :group, venue: venue, priced_duration: :hour }

      it 'returns calculated price' do
        is_expected.to eq (group.participation_price * 2)
      end
    end

    context 'price per season' do
      let(:group) { create :group, venue: venue, priced_duration: :season }

      it 'returns calculated price' do
        is_expected.to eq (group.participation_price)
      end
    end
  end

  describe '#users_with_groups scope' do
    subject { Reservation.users_with_groups(users) }

    let(:group) { create :group, venue: venue, priced_duration: :season }
    let!(:group_reservation) { create :reservation, user: group }
    let!(:user_reservation) { create :reservation, user: group.owner }
    let!(:other_reservation) { create :reservation }

    context 'multiple users' do
      let(:users) { [group.owner, other_reservation.user] }

      it 'returns reservsations for all users' do
        is_expected.to match_array [group_reservation, user_reservation, other_reservation]
      end
    end

    context 'single user' do
      let(:users) { group.owner }

      it 'returns reservsations for user' do
        is_expected.to match_array [group_reservation, user_reservation]
      end
    end
  end

  describe '#update_counter_cache' do
    let(:group) { create :group, venue: venue, priced_duration: :season }
    let!(:group_reservation) { create :reservation, user: group }
    let!(:participation) { create :participation, reservation: group_reservation }
    let(:create_participation) { create :participation, reservation: group_reservation }

    it 'increases count on participation creation' do
      expect{ create_participation }.to change{ group_reservation.reload.participations_count }.by(1)
    end

    it 'decreases count on participation deletion' do
      expect{ participation.destroy }.to change{ group_reservation.reload.participations_count }.by(-1)
    end

    it 'decreases count on participation cancellation' do
      expect{ participation.cancel }.to change{ group_reservation.reload.participations_count }.by(-1)
    end
  end

  describe 'group participation mail' do
    let!(:venue) { create :venue }
    let!(:group) { create :group, users: participants }
    context 'when a reservation where I am a participant VIA the group, has been created' do
      subject { create :group_reservation, venue: venue, user: group }
      let(:participants) { [ create(:user) ] }

      before do
        participants.each do |participant|
          # note: cannot pass reservation here, as it is not created yet
          # also, really weird bug: RSpec thinks ReservationMailer is called twice,
          # while in fact it is called only once
          expect(ReservationMailer).to receive(:participant_added_for_participant).
            with(participant, instance_of(Reservation), instance_of(Hash)).at_most(:twice).and_call_original
        end
      end

      it 'mails both' do
        # +1 for the owner
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(participants.size + 1)
      end

      it 'mails only one if disabled for other' do
        participants.first.settings(:email_notifications).put(:reservation_receipts, false)
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(participants.size)
      end
    end

    context 'when reservation is changed' do
      let!(:reservation) { create :group_reservation, venue: venue, user: group }
      let(:participants) { [ create(:user), create(:user) ] }

      context 'when cancelling reservation' do
        subject { reservation.cancel(create(:admin, company: venue.company)) }

        before do
          expect(CancellationMailer).to receive(:admin_cancellation_email).
            at_most(:twice).with(group, reservation, instance_of(Hash)).and_call_original
          participants.each do |participant|
            expect(CancellationMailer).to receive(:admin_cancellation_email).
              at_most(:twice).with(participant, reservation, instance_of(Hash)).and_call_original
          end
        end

        # we hit notify participant for this?
        it 'mails the participants' do
          expect { subject }.to change {
            ActionMailer::Base.deliveries.count
          }.by(3)
        end

        it 'mails only one if disabled for other' do
          participants.first.settings(:email_notifications).put(:reservation_cancellations, false)
          expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(2)
        end
      end

      context 'when updating the reservation' do
        let!(:new_court) { create :court, venue: venue }
        subject { reservation.update_attributes! court_id: new_court.id }

        before do
          expect(ReservationMailer).to receive(:reservation_updated).
            at_most(:twice).with(group, reservation, instance_of(Hash)).and_call_original
          participants.each do |participant|
            # RSpec bug with double message receiving
            expect(ReservationMailer).to receive(:reservation_updated)
              .with(participant, reservation, instance_of(Hash)).at_most(:twice).and_call_original
          end
        end

        it 'mails the participants' do
          expect { subject }.to change {
            ActionMailer::Base.deliveries.count
          }.by(3)
        end

        it 'mails only one if disabled for other' do
          participants.first.settings(:email_notifications).put(:reservation_updates, false)
          expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(2)
        end
      end
    end
  end

end
