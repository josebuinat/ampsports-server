class API::Users::SubscriptionsController < API::BaseController
  before_action :authenticate_request!

  def venues
    @venues = venues_with_photos
  end

  def toggle_email_subscription
    venue = current_user.venues.find(params[:venue_id])
    if current_user.toggle_email_subscription_for(venue)
      @venues = venues_with_photos
      render :venues
    else
      render json: { errors: [I18n.t('api.users.subscriptions.toggle_error')] }, status: :unprocessable_entity
    end
  end

  private

  def venues_with_photos
    current_user.venues.includes(:photos).order(:venue_name)
  end
end
