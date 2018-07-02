require 'rails_helper'

describe API::MailchimpSubscribersController, type: :controller do
  describe 'POST create' do
    subject { post :create, email: 'test@example.com' }

    before { ENV['MAILCHIMP_LIST_ID'] = 'list_id' }

    it { is_expected.to be_success }

    it 'enques a job to Sidekiq' do
      subject
      expect(MailchimpWorker.jobs.size).to eql 1
    end
  end
end
