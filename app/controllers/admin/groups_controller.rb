# groups search
class Admin::GroupsController < Admin::BaseController
  def index
    @groups = authorized_scope(company.groups).base_includes
    @groups = @groups.where(venue: venue) if venue
    @groups = @groups.for_coach(coach) if coach
    @groups = @groups.for_user(user) if user
    @groups = @groups.search(params[:search]) if params[:search].present?
    @groups = @groups.sort_on(params[:sort_on]) if params[:sort_on].present?
    @groups = @groups.paginate(page: params[:page])
  end

  private

  def company
    current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id]) if params[:venue_id].present?
  end

  def coach
    @coach ||= company.coaches.find(params[:coach_id]) if params[:coach_id].present?
  end

  def user
    @user ||= company.users.find(params[:user_id]) if params[:user_id].present?
  end
end
