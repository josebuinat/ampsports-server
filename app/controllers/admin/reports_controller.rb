class Admin::ReportsController < Admin::BaseController
  # as we respond in XLS/PDF there
  skip_before_action :set_default_response_format, only: [:payment_transfers,
                                                          :download_sales_report,
                                                          :download_invoices_report]
  around_action :use_timezone

  def index
    authorize :report

    @revenue = RevenueCalculator.new(company, venue_param, start_param, end_param, sport_name).call
    @utilization = UtilizationCalculator.new(company, venue_param, start_param, end_param, sport_name).call
    @bookings = BookingsCalculator.new(company, venue_param, start_param, end_param, sport_name).call
    @unsold = UnsoldCalculator.new(company, venue_param, start_param, end_param, sport_name).call
  end

  # separate action, as this one makes a stripe API call
  def payment_transfers
    authorize :report

    @transfers = company.transfers(start_param, end_param)
    # @transfers = company.transfers(300.days.ago.to_s, Date.current.to_s)

    respond_to do |format|
      format.json
      format.pdf { render '/companies/report' }
    end
  end

  def download_sales_report
    authorize :report

    report = Excel::VenueReport.new(current_admin, venue).generate(start_time, end_time)
    send_data report.to_stream.read, filename: report.filename
  end

  def download_invoices_report
    authorize :report

    report = Excel::InvoiceReport.new(current_admin).generate(start_time, end_time)
    send_data report.to_stream.read, filename: report.filename
  end

  # other sport name actions are scoped to venue; we need all possible sport names for all venues
  def sport_name_options
    authorize :report

    sport_names = company.venues.
      flat_map { |venue| venue.supported_sports_options }.
      uniq { |hash| hash[:value] }

    render json: sport_names
  end

  private

  def start_param
    params[:start] || Date.current.to_s
  end

  def end_param
    params[:end] || Date.current.to_s
  end

  def start_time
    TimeSanitizer.input(TimeSanitizer.output(start_param).beginning_of_day.to_s)
  end

  def end_time
    TimeSanitizer.input(TimeSanitizer.output(end_param).end_of_day.to_s)
  end

  def venue_param
    params[:venue_id].to_i > 0 ? params[:venue_id] : nil
  end

  def venue
    @venue ||= venue_param ? company.venues.find(venue_param) : company.venues.first
  end

  def sport_name
    params[:sport_name].present? ? params[:sport_name] : nil
  end

  def company
    @company ||= current_admin.company
  end
end
