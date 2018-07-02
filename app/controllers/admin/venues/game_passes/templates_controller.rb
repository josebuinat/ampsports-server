class Admin::Venues::GamePasses::TemplatesController < Admin::BaseController
  def index
    authorize GamePass
  end

  def select_options
    @templates = authorized_scope GamePass.templates.where(venue_id: venue.id)
  end

  private

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end
end