class MailchimpWorker
  include Sidekiq::Worker

  def perform(list_id, email)
    MailchimpService.add_email_to_list(list_id: list_id, email: email)
  end

  def self.add_user_to_list(email)
    perform_async(ENV['MAILCHIMP_USER_LIST_ID'], email)
  end

  def self.add_venue_to_list(email)
    perform_async(ENV['MAILCHIMP_VENUE_LIST_ID'], email)
  end
end
