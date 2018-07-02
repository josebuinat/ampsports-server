require 'rails_helper'

describe CancellationMailer, type: :mailer do
  describe 'admin_cancellation_email' do
    let(:reservation) { create :reservation }
    let(:user) { reservation.user }
    let(:venue) { reservation.court.venue }
    let(:date) { Time.with_user_clock_type(user) { reservation.start_time.to_s(:date) } }
    let(:mail) { described_class.admin_cancellation_email(user, reservation).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eql I18n.t('cancellation_mailer.admin_cancellation_email.subject',
                                    start: date,
                                    venue: venue.venue_name,
                                    locale: user.locale)
    end

    it 'sets correct "to"' do
      expect(mail.to).to eql [user.email]
    end

    it 'sets correct "from"' do
      expect(mail.from).to eql ['no-reply@playven.com']
    end

    it 'renders correct body' do
      expect(mail.body.encoded).to match(date)
      expect(mail.body.encoded).to match(venue.venue_name)
    end
  end

  describe '#user_cancellation_email' do
    let(:reservation) { create :reservation }
    let(:user) { reservation.user }

    subject { described_class.user_cancellation_email(user, reservation).deliver_now! }

    it 'sends an email' do
      expect { subject }.to change { ActionMailer::Base.deliveries.count }
    end

    context 'when user is not interested in emails' do
      before { user.email_notifications.put :reservation_cancellations, false }

      it 'does not send anything' do
        expect { subject }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end
end
