class Admin::Venues::DashboardController < Admin::BaseController
  around_action :use_timezone

  def show
    authorize [:venue, :dashboard]

    today = Date.current.to_s
    week_ago = 6.days.ago.to_date.to_s
    @utilization_calculator = UtilizationCalculator.new(company, venue.id, today, today).call
    @bookings_calculator = BookingsCalculator.new(company, venue.id, today, today).call
    @today_unsold_calculator = UnsoldCalculator.new(company, venue.id, today, today).call
    @week_ago_unsold_calculator = UnsoldCalculator.new(company, venue.id, week_ago, today).call
    @today_revenue_calculator = RevenueCalculator.new(company, venue.id, today, today).call
    @week_ago_revenue_calculator = RevenueCalculator.new(company, venue.id, week_ago, today).call
  end

  private

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end
end
