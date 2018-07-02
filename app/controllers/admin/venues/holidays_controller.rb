class Admin::Venues::HolidaysController < Admin::BaseController
  around_action :use_timezone

  def index
    @holidays = authorized_scope(venue.holidays).includes(:courts)
    @holidays = @holidays.search(params[:search]) if params[:search].present?
    @holidays = @holidays.sort_on(params[:sort_on]) if params[:sort_on].present?
    @holidays = @holidays.paginate(page: params[:page])
  end

  # action for calendar
  def all_for_calendar
    response = authorized_scope(venue.holidays)
    if params[:sport].present?
      response = response.where courts: { sport_name: Court.sport_names[params[:sport]] }
    end

    # "for_whole_venue" means "squash" all courts holidays into one timeline. In other words, if
    # at least one court is working, then it's not a holiday for a venue
    if params[:for_whole_venue]
      response = response.select(&:for_whole_venue?)
    end


    render json: response
  end

  def show
    holiday
  end

  def update
    if holiday.update(update_params)
      render 'show'
    else
      render json: { errors: holiday.errors }, status: :unprocessable_entity
    end
  end

  def create
    @holiday = authorize Holiday.new(create_params)
    if @holiday.save
      render 'show', status: :created
    else
      render json: { errors: holiday.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    holiday.destroy
    render json: [holiday.id]
  end

  def destroy_many
    deleted_ids = params.require(:holiday_ids).select do |holiday_id|
      authorized_scope(venue.holidays).find_by(id: holiday_id)&.destroy
    end

    render json: deleted_ids
  end

  private

  def update_params
    # TODO: add check that all court_ids are controller by current admin
    # allow court_ids twice to allow passing an empty array (or nil) to delete them all
    permitted = params.require(:holiday).permit(:court_ids, court_ids: [])
    if params.dig(:holiday, :use_all_courts)
      permitted.merge!(court_ids: venue.court_ids)
    end

    start_time_param = params.dig(:holiday, :start_time)
    end_time_param = params.dig(:holiday, :end_time)

    time_params = { start_time: start_time_param && TimeSanitizer.input(start_time_param),
      end_time: end_time_param && TimeSanitizer.input(end_time_param) }.reject { |k, v| v.blank? }

    permitted.merge! time_params
    permitted.permit!
  end

  def create_params
    update_params
  end

  def holiday
    @holiday ||= authorized_scope(venue.holidays).find(params[:id])
  end

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end
end
