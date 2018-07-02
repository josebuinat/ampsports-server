class Admin::VenuesController < Admin::BaseController
  around_action :use_timezone, only: :closing_hours

  def index
    @venues = authorized_scope(company.venues)
  end

  def show
    venue
  end

  def closing_hours
    render json: venue.closing_hours
  end

  def create
    @venue = authorize company.venues.build(create_params)
    if @venue.save
      update_settings
      MailchimpWorker.add_venue_to_list(current_admin.email)
      render 'show', status: :created
    else
      render json: { errors: @venue.errors }, status: :unprocessable_entity
    end
  end

  def update
    if venue.update(update_params)
      update_settings
      render 'show'
    else
      render json: { errors: venue.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    venue.destroy
    render json: [@venue.id]
  end

  # TODO: move these 2 select options to collection actions of courts
  def select_options_for_court_sports
    @court_sports_enums = Court.where(venue_id: authorized_scope(company.venues).select(:id)).active.
      pluck('distinct sport_name')
    @court_sports = @court_sports_enums.map { |n| Court.sport_names.key(n) }
    render json: @court_sports.map { |x| { value: x, label: x.humanize } }
  end

  def select_options_for_court_surfaces
    @court_surfaces = venue.courts.map(&:surface).uniq.compact
    render json: @court_surfaces.map { |x| { value: x, label: x.humanize} }
  end

  # hits 3rd party services to get a forecast or weather history
  def weather
    # empty array dates is still fine, not a reason for 400 (happens for venues without courts)
    render json: {} and return if params.dig(:dates).blank?

    forecast = WeatherForecaster.call(venue, [*params.require(:dates)])
    json = forecast.transform_values do |value|
      value ? value.slice(*%w(icon temperature)) : nil
    end
    render json: json
  end

  private

  def update_params
    # .permit(business_hours: {mon: [:opening, :closing]})
    permitted_business_hours = %i(mon tue wed thu fri sat sun).reduce({}) do |sum, item|
      sum.merge(item => [:opening, :closing])
    end

    raw_business_hours = params.require(:venue).permit(business_hours: permitted_business_hours).dig(:business_hours)
    business_hours = raw_business_hours && raw_business_hours.transform_values do |hash|
      hash.transform_values { |value| value.to_i }
    end

    params.require(:venue).permit(policy(Venue).permitted_attributes).tap do |permitted_params|
      if !current_admin.respond_to?(:god?) || !current_admin.god?
        permitted_params.delete(:timezone)
      end
      if business_hours && policy(Venue).permitted_business_hours
        permitted_params.merge!(business_hours: business_hours).permit!
      end
    end
  end

  def create_params
    update_params
  end

  def update_settings
    params.require(:venue).permit(policy(Venue).permitted_settings)[:settings].to_h.each do |scope, settings|
      settings.each do |name, velue|
        venue.settings(scope).put(name, velue)
      end
    end
  end

  def venue
    @venue ||= authorized_scope(company.venues).find(params[:id])
  end

  def company
    @company ||= current_admin.company
  end
end
