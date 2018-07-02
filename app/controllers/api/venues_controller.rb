class API::VenuesController < API::BaseController
  before_action :set_venue, only: [:users, :sports, :show, :courts, :make_favourite, :unfavourite, :available_courts]
  before_action :authenticate_request!, only: [:make_favourite, :unfavourite, :favourites]
  around_action :use_timezone, only: [:show, :courts, :utilization_rate, :available_courts]

  def index
    @venues = Venue.viewable.includes(:courts, :photos)
    @venues = @venues.sport(params[:sport]) if params[:sport].present?
    @venues = @venues.by_city(params[:city]) if params[:city].present?
    if params[:country].present?
      country = Country.find_country(params[:country])
      @venues = @venues.by_country(country.id)
    end
    @venues = @venues.order(:status, created_at: :desc)
  end

  def users
    @users = @venue.users
      .merge(User.search(params[:q]))
      .select(:id, :first_name, :last_name, :email)
      .distinct
      .map { |u|
        {
          value: u.id,
          label: [u.first_name.capitalize, u.last_name.capitalize, u.email].join(' ')
        }
    }
  end

  def show
  end

  def courts
    @courts = @venue.courts
  end

  def sports
    render json: @venue.supported_sports_options
  end

  def all_sport_names
    @sport_names = Venue.all_sport_names
  end

  def utilization_rate
    v = Venue.find(params[:venue_id])
    @times = []
    @rates = []
    time = TimeSanitizer.output(v.opening(Date.current.strftime("%a").underscore))
    while time < TimeSanitizer.output(v.closing(Date.current.strftime("%a").underscore))
      bookings = 0.0
      v.courts.each do |court|
        if court.reservations.where("? >= start_time AND ? < end_time", time, time)
          .length > 0
          bookings += 1
        end
      end
      @times << time.to_s(:user_clock_time)

      courts_count = v.courts.count
      @rates <<  if courts_count > 0
          ((bookings/v.courts.count) * 100).round
        else
          0
        end
      time += 1.hour
    end
  end

  def sort_by_sport
    @sport = params[:sport]
    case @sport
    when 'tennis'
      @venues = Venue.searchable
    when 'padel'
      @venues = Venue.searchable.padel
    else
      @sport = 'tennis'
      @venues = Venue.searchable.tennis
    end
  end

  def available_courts
    @search = Search::OnVenue.new(
      sport_name: params[:sport_name],
      venue: params[:venue_id],
      date: TimeSanitizer.input(params[:date])
    ).call
    SegmentAnalytics.search_for_venue(@current_user,
                                     @venue,
                                     {
                                       sport_name: params[:sport_name],
                                       search_date: @search.date
                                     })
  end

  def make_favourite
    @venues = @current_user.favourites.push(@venue)
    render :index
  end

  def unfavourite
    @current_user.favourites.delete(@venue)
    @venues = @current_user.favourites
    render :index
  end

  def favourites
    @venues = @current_user.favourites
    render :index
  end

  def group_classifications
    render json: Venue.find(params[:venue_id]).group_classifications.map { |classification|
      { value: classification.id, label: classification.name }
    }
  end
  private

  def set_venue
    @venue = Venue.find(params[:venue_id] || params[:id])
  end

  def use_timezone
    venue = @venue || Venue.find_by(id: params[:venue_id] || params[:id])
    if venue
      Time.use_zone(venue.timezone) { yield }
    else
      yield
    end
  end
end
