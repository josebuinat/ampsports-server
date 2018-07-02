require 'rails_helper'

describe MailchimpService do
  describe '#add_to_list' do
    before do
      ENV['MAILCHIMP_API_KEY'] = '6687dfa'
    end
    let(:lists) { double(:lists ) }
    let(:members) { double(:members ) }
    let(:request) { double(:request) }

    it 'reads API key from ENV' do
      expect(Gibbon::Request).to receive(:new).with(api_key: '6687dfa').and_return(request)
      expect(request).to receive(:lists).with('123').and_return(lists)
      expect(lists).to receive(:members).with(Digest::MD5.hexdigest('test@example.com')).and_return(members)
      expect(members).to receive(:upsert).with(body: { email_address: 'test@example.com', status: 'subscribed' })

      MailchimpService.add_email_to_list(list_id: '123', email: 'test@example.com')
    end
  end
end
