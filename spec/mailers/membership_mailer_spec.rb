require 'rails_helper'

describe MembershipMailer, type: :mailer do
  describe '#membership_created' do
    let(:membership) { create :membership, :with_reservations }
    let(:user) { membership.user }
    subject { described_class.membership_created(user, membership).deliver_now! }

    it 'sends an email' do
      expect { subject }.to change { ActionMailer::Base.deliveries.count }
    end

    context 'when company prohibits emailing the users' do
      let(:company) { membership.venue.company }
      before { company.email_notifications.put :membership_created, false }

      it 'does not send anything' do
        expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end
end
