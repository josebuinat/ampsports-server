class MailchimpService
  class << self

    def add_email_to_list(list_id:, email:)
      gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
      email_hash = Digest::MD5.hexdigest(email.downcase)
      request_body = { email_address: email, status: 'subscribed' }
      gibbon.lists(list_id).members(email_hash).upsert(body: request_body)
    rescue Gibbon::MailChimpError => e
      custom_params = { raw_body: e.raw_body }
      Rollbar.error(e, 'Error while adding subscriber email', custom_params)
    end
  end
end
