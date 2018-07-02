class Admin::Venues::CourtsController < Admin::BaseController
  # as we respond in PDF there
  skip_before_action :set_default_response_format, only: [:calendar_print]
  around_action :use_timezone

  def index
    @courts = authorized_scope(venue.courts)
    @courts = @courts.search(params[:search]) if params[:search].present?
    @courts = @courts.sort_on(params[:sort_on]) if params[:sort_on].present?
    @courts = @courts.paginate(page: params[:page])
  end

  def show
    court
  end

  def update
    if court.update(update_params)
      render 'show'
    else
      render json: { errors: court.errors }, status: :unprocessable_entity
    end
  end

  def create
    indexes = available_indexes_for_create

    @court = authorize venue.courts.build(create_params.merge(index: indexes.shift))
    if @court.save
      # this is not super-correct (create should create only one instance!),
      # but we're totally acting like we are created just one
      failed_clones_count = create_court_copies_count.times.map do
        venue.courts.build(create_params.merge(index: indexes.shift)).save
      end.count { |x| !x }

      if failed_clones_count > 0
        Rollbar.error("Failed to create #{failed_clones_count} court clones", create_params: create_params)
      end
      render 'show', status: :created
    else
      render json: { errors: @court.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    court.destroy
    render json: [court.id]
  end

  def destroy_many
    deleted_ids = params.require(:court_ids).select do |court_id|
      authorized_scope(company.courts).find_by(id: court_id)&.destroy
    end

    render json: deleted_ids
  end

  def select_options
    render json: (authorized_scope(venue.courts).where.not(id: params[:ignore_court_id].to_i).map do |court|
      {
        value: court.id,
        label: params[:with_sport_names].present? ? court.court_name_with_sport : court.court_name
      }
    end)
  end

  def available_select_options
    include_court_id = params[:include_court_id].to_i

    scope = authorized_scope(venue.courts).includes(:reservations)
    scope = scope.for_sport(params[:sport]) if params[:sport].present?

    available_courts = scope.to_a.
      select { |court| court.id == include_court_id || court.available_on?(time_frame) }.
      map { |court| {value: court.id, label: court.court_name} }

    render json: available_courts
  end

  # action for calendar
  def active
    authorize Court

    render json: venue.active_courts_json
  end

  # action for calendar
  def calendar_resources
    @courts = authorized_scope(venue.courts.active)
    if params[:sport].present? && params[:sport] != 'all'
      @courts = @courts.select { |court| court.sport_name == params[:sport] }
    end
    if params[:surface].present? && params[:surface] != 'all'
      @courts = @courts.select { |court| court.surface == params[:surface] }
    end

    @courts = @courts.sort_by{ |c| [ c.sport_name, (c.indoor ? 0 : 1), c.index ] }

    # color to be the same as in css for disabled. We see resource (court) on calendar only on
    # unbookable zones (on "bookable" zones we see "bookable" color). So, paint all reservations
    # disabled, gray color!
    disabled_color = '#F4F7F9'

    json = @courts.map do |court|
      {
        id: court.id,
        title: court.court_name,
        title_with_sport: "#{court.court_name} (#{court.sport})",
        sport_name: court.sport_name,
        eventColor: disabled_color
      }
    end
    render json: json
  end

  # action for calendar
  def prices_at
    prices = params.require(:reservations).map do |reservation_params|
      # we use find_by because it does not raise a error; coach calendar requires user to specify
      # court_id, so we may end up in a situation when request is made, but court_id is not yet set.
      court = authorized_scope(venue.courts).find_by id: reservation_params[:court_id]
      reservation_mock = Reservation.new do |reservation|
        reservation.assign_attributes({
          court: court,
          start_time: TimeSanitizer.input("#{reservation_params[:date]} #{reservation_params[:start_tact]}"),
          end_time: TimeSanitizer.input("#{reservation_params[:date]} #{reservation_params[:end_tact]}"),
          user_type: params[:user_type],
          user_id: params[:user_id],
          classification_id: params[:classification_id],
          coach_ids: reservation_params[:coach_ids],
        })
      end

      reservation_mock.calculate_price
    end

    render json: { prices: prices }
  end

  # print action for calendar
  def calendar_print
    date = TimeSanitizer.input(params[:calendar_date])
    @calendar_date = date.strftime("%A, %B %-d")
    @day = date.strftime("%a").downcase
    @courts = authorized_scope(venue.courts)
    @courts = @courts.sort_by{ |c| [ c.sport_name, (c.indoor ? 0 : 1), c.index ] }
  end

  def available_indexes
    authorize Court

    for_court = Court.find_by(id: params[:existing_court])

    court = Court.new(
      id: for_court&.id,
      indoor: params[:indoor] == 'true' ? true : false,
      sport_name: params[:sport_name].to_s,
      custom_name: params[:custom_name].to_s
    )

    indexes = venue.available_court_indexes(court, params[:copies].to_i)

    render json: indexes
  end

  def available_indexes_for_create
    court = Court.new(
      indoor: create_params[:indoor],
      sport_name: create_params[:sport_name].to_s,
      custom_name: create_params[:custom_name].to_s
    )

    venue.available_court_indexes(court, params[:create_copies_count].to_i).
      reject { |n|  n < create_params[:index].to_i }
  end

  protected

  def http_auth_token
    # authorize through query string, as this is a pdf page
    if params[:action] == 'calendar_print'
      params[:auth_token]
    else
      super
    end
  end

  private

  def update_params
    params.require(:court).permit(:index, :sport_name, :custom_name, :surface, :court_description, :private,
      :duration_policy, :start_time_policy, :indoor, :active, :payment_skippable, :shared_court_ids, shared_court_ids: [])
  end

  def create_params
    update_params
  end

  def create_court_copies_count
    copies = params[:create_copies_count].to_i || 0
    copies = 0 if copies < 0
    copies = 49 if copies > 49 # prevent DOS
    copies
  end

  def time_frame
    @time_frame ||= TimeFrame.new(TimeSanitizer.input(params[:start_time]),
                                  TimeSanitizer.input(params[:end_time]))
  end

  def court
    @court ||= venue.courts.find(params[:id])
  end

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end
end
