class Admin::Venues::Groups::ReservationsController < Admin::BaseController
  around_action :use_timezone

  def index
    @reservations = authorized_scope(group.reservations).
                          includes(:user, :coaches, :court, :venue).
                          order(:start_time).
                          paginate(page: params[:page])
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
end
