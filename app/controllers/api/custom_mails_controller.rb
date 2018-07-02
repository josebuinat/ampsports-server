class API::CustomMailsController < API::BaseController
  before_action :authenticate_admin!
  before_action :set_venue

  def index
    @custom_mails = @venue.custom_mails.
      includes(:email_lists).
      merge(CustomMail.search(params[:search_term])).
      order(created_at: :desc)
  end

  private

  def set_venue
    @venue = Venue.find(params[:venue_id])
  end
end
