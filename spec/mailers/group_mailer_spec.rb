require 'rails_helper'

describe GroupMailer, type: :mailer do
  let!(:group) { create :group }
  let!(:user) { create :user }

  describe '#added_to_the_group' do
    subject { described_class.added_to_the_group(group, user).deliver_now! }

    it 'sends an email' do
      expect { subject }.to change { ActionMailer::Base.deliveries.count }
    end

    context 'when company prohibits emailing the users' do
      let(:company) { group.company }
      before { company.email_notifications.put :added_to_the_group, false }

      it 'does not send anything' do
        expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end

  describe '#removed_from_the_group' do
    subject { described_class.removed_from_the_group(group, user).deliver_now! }

    it 'sends an email' do
      expect { subject }.to change { ActionMailer::Base.deliveries.count }
    end

    context 'when company prohibits emailing the users' do
      let(:company) { group.company }
      before { company.email_notifications.put :removed_from_the_group, false }

      it 'does not send anything' do
        expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end

end
