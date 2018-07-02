require 'rails_helper'

describe MailchimpWorker, sidekiq: :inline do
  it 'calls MailchimpService' do
    expect(::MailchimpService).to receive(:add_email_to_list).with(list_id: 'list_id', email: 'test@example.com')
    MailchimpWorker.perform_async('list_id', 'test@example.com')
  end

  describe '#add_user_to_list' do
    before { ENV['MAILCHIMP_USER_LIST_ID'] = "test-user-list" }

    it 'enques a job to Sidekiq' do
      expect(::MailchimpService).to receive(:add_email_to_list).with(list_id: 'test-user-list', email: 'test@playven.com')
      MailchimpWorker.add_user_to_list("test@playven.com")
    end
  end

  describe '#add_venue_to_list' do
    before { ENV['MAILCHIMP_VENUE_LIST_ID'] = "test-venue-list" }

    it 'enques a job to Sidekiq' do
      expect(::MailchimpService).to receive(:add_email_to_list).with(list_id: 'test-venue-list', email: 'test@playven.com')
      MailchimpWorker.add_venue_to_list("test@playven.com")
    end
  end
end
