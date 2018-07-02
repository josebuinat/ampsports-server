require 'rails_helper'

describe Reservation::ParticipantConnection, type: :model do
  describe 'auto-assigning price and amount paid from reservation' do
    # important: for user reservations the first participant is the owner, so using guest here
    let!(:owner) { create :guest }
    let!(:reservation) { create :reservation, price: 100, amount_paid: 50, user: owner }

    before { reservation.participant_connections_attributes = nested_attributes }
    let!(:user_1) { create :user }
    let!(:user_2) { create :user }

    subject { reservation.save!; reservation.reload; }

    let(:first_connection) { reservation.participant_connections.first }
    let(:last_connection) { reservation.participant_connections.last }

    context 'when reservation has the only one participant' do
      let(:nested_attributes) { [ { user_id: user_1.id } ] }

      it 'assigns everything to it' do
        expect { subject }.to change { Reservation::ParticipantConnection.count }.by(1)
        expect(first_connection).to have_attributes price: 100, amount_paid: 50
      end
    end

    context 'when reservation has 2 participants' do
      let(:nested_attributes) { [ { user_id: user_1.id }, { user_id: user_2.id, price: 20, amount_paid: 10 } ] }

      it 'minds its own business' do
        expect { subject }.to change { Reservation::ParticipantConnection.count }.by(2)
        expect(first_connection).to have_attributes price: 0, amount_paid: 0
        expect(last_connection).to have_attributes price: 20, amount_paid: 10
      end
    end
  end

  describe 'mailers' do
    let(:override_should_send_emails) { nil }
    let!(:participant_1) { create :user }
    let!(:participant_2) { create :user }
    let!(:coach) { create :coach, :available, for_court: court }
    let(:court) { create :court }

    describe 'participants created with reservation' do
      subject do
        create :reservation, participant_ids: [participant_1.id, participant_2.id], coach_ids: [coach.id],
          override_should_send_emails: override_should_send_emails, court: court
      end

      it 'sends welcome emails to all users and a coach' do
        # 1 created + 2 participants (you've been added) + coach assigned + 2 participants added for coach
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(6)
      end

      context 'when send emails flag is turned off' do
        let(:override_should_send_emails) { false }

        it 'does not send emails' do
          expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end

    describe 'participants added to an existing reservation' do
      let!(:reservation) { create :reservation }
      let(:court) { reservation.court }

      subject do
        reservation.update participant_connections_attributes: [
          { user_id: participant_1.id, price: 10 },
          { user_id: participant_2.id, price: 10 },
        ], override_should_send_emails: override_should_send_emails, coach_ids: [coach.id]
      end
      let(:override_should_send_emails){ nil }

      it 'sends welcome email to new users and a coach' do
        # 1 you are the coach + 2 participants have been added (to coach) + 2 participants (You've been added)
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(5)
      end

      context 'when send emails flag is turned off' do
        let(:override_should_send_emails) { false }

        it 'does not send emails' do
          expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end

    describe 'participants removed from an existing reservation' do
      let!(:participant) { create :user }
      let!(:reservation) { create :reservation, participants: [participant] }

      subject do
        reservation.update participant_connections_attributes: [
          { id: reservation.participant_connections.first.id, _destroy: true }
        ], override_should_send_emails: override_should_send_emails
      end

      it 'sends email to the participant' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      context 'when send email flag is turned off' do
        let(:override_should_send_emails) { false }

        it 'does not send email to the participant' do
          expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end
  end
end
