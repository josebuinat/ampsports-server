class Admin::Venues::Coaches::ReportsController < Admin::BaseController
  around_action :use_timezone
  around_action :use_clock_type, only: [:download]
  # as we respond in XLS/PDF there
  skip_before_action :set_default_response_format, only: [:download]

  def index
    @salary_report = Coach::Reports::SalaryCalculator.new(coach, venue, **report_params)
  end

  def download
    report = Excel::CoachReport.new(coach, current_admin, venue).generate(**report_params)
    send_data report.to_stream.read, filename: report.filename
  end

  private

  def report_params
    params.permit(:start_date, :end_date, :sport).symbolize_keys
  end

  def coach
    # this is an extended data of coach, so we can authorize coach himself
    @coach ||= authorized_scope(company.coaches).find(params[:coach_id])
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end

  def company
    @company ||= current_admin.company
  end
end
