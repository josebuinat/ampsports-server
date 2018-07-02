require 'rails_helper'

describe Reservation::ParticipantConnection, type: :model do
  describe 'a coach removed from an existing reservation' do
    let!(:court) { create :court }
    let!(:coach) { create :coach, :available, for_court: court }
    let!(:reservation) { create :reservation, coach_ids: [coach.id], court: court }

    subject { reservation.update override_should_send_emails: override_should_send_emails, coach_ids: []  }

    let(:override_should_send_emails) { nil }

    it 'sends email to the removed coach' do
      expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    context 'when send email flag is turned off' do
      let(:override_should_send_emails) { false }

      it 'does not send any messages' do
        expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end
end
