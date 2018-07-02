class Admin::Venues::Groups::SubscriptionsController < Admin::BaseController
  around_action :use_timezone

  def index
    @subscriptions = authorized_scope(group.subscriptions).
                           active.
                           includes(:user, :group_season, :group).
                           order(:created_at).
                           paginate(page: params[:page])
  end

  def destroy
    if subscription.cancelable? && subscription.cancel
      render json: [subscription.id]
    else
      head :unprocessable_entity
    end
  end

  def destroy_many
    cancelled = many_subscriptions.select do |subscription|
      subscription.cancelable? && subscription.cancel
    end

    render json: cancelled.map(&:id)
  end

  def mark_paid_many
    marked_paid = many_subscriptions.select do |subscription|
      subscription.payable? && subscription.mark_paid(params[:amount])
    end

    render json: marked_paid.map(&:id)
  end

  def mark_unpaid_many
    marked_unpaid = many_subscriptions.select do |subscription|
      subscription.unpayable? && subscription.mark_unpaid
    end

    render json: marked_unpaid.map(&:id)
  end

  private

  def company
    current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end

  def group
    @group ||= venue.groups.find(params[:group_id])
  end

  def subscription
    @subscription ||= authorized_scope(group.subscriptions).active.find(params[:id])
  end

  def many_subscriptions
    @many_subscriptions ||= authorized_scope(group.subscriptions).
                              active.where(id: params[:subscription_ids])
  end
end
