class API::MailchimpSubscribersController < API::BaseController

  def create
    MailchimpWorker.perform_async(ENV['MAILCHIMP_LIST_ID'], params[:email])
    head :ok
  end

end
