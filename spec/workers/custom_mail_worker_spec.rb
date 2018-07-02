require 'rails_helper'

describe CustomMailWorker do
  let(:venue) { create :venue }
  let(:email) { 'mika-hakkinen@f1.com' }
  let!(:custom_mail) { create :custom_mail, venue: venue, recipient_users: email }

  it 'logs errors to Rollbar' do
    allow_any_instance_of(Mail::Message).to receive(:deliver).and_raise(Net::SMTPSyntaxError)

    expect(Rollbar).to receive(:error).with(
      instance_of(Net::SMTPSyntaxError),
      'Error while sending custom email',
      {
        to: email,
        custom_mail_id: custom_mail.id
      }
    )
    CustomMailWorker.new.perform(custom_mail.id)
  end
end
