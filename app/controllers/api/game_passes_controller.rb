class API::GamePassesController < API::BaseController
  before_action :authenticate_admin!, except: [:available]
  before_action :set_venue, only: [:index, :create, :templates, :available, :court_sports]
  before_action :set_game_pass, only: [:show, :update, :destroy]

  around_action :use_timezone, only: [:create, :index, :show, :templates, :available]

  def index
    @game_passes = @venue.game_passes.includes(:user, :coaches).order(:created_at)
  end

  def show
  end

  def create
    game_pass = GamePass.new(create_game_pass_params)

    if game_pass.save
      if params[:template_name].present?
        template = game_pass.dup
        template.template_name = params[:template_name]
        template.user_id = nil
        template.save
      end

      head :ok
    else
      render nothing: true, status: :unprocessable_entity
    end
  end

  def update
    if @game_pass.update(update_game_pass_params)
      if params[:template_name].present?
        template = @game_pass.dup
        template.template_name = params[:template_name]
        template.user_id = nil
        template.save
      end

      head :ok
    else
      head :unprocessable_entity
    end
  end

  def destroy
    if @game_pass.destroy
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def available
    # fallback for erb version, while making it work for react
    user =
      if params[:user_id].present?
        User.find(params[:user_id])
      else
        authenticate_request!
        current_user
      end
    start_time = TimeSanitizer.input(params[:start_time].to_s).in_time_zone
    end_time =
      if params[:end_time].present?
        TimeSanitizer.input(params[:end_time].to_s).in_time_zone
      elsif params[:duration].present?
        start_time + params[:duration].to_i.minutes
      end
    court = @venue.courts.find(params[:court_id])
    coach_ids = params[:coach_ids].to_a.map(&:to_i)

    game_passes = user.
      available_game_passes(court, start_time, end_time, coach_ids).
      map { |game_pass|
      {
        value: game_pass.id,
        label: game_pass.auto_name,
        remaining_charges: game_pass.remaining_charges
      }
    }

    render json:  game_passes
  end

  def templates
    @templates = @venue.game_passes.templates
  end

  # Should not be used, use the one from venue
  # controller instead
  def court_sports
    render json: @venue.supported_sports_options
  end

  # Should not be used, use the one from court
  # controller instead
  def court_types
    render json:  GamePass.court_types_options
  end

  private

  def set_game_pass
    @game_pass = GamePass.find(params[:id])
  end

  def set_venue
    @venue = if params[:venue_id].present?
      Venue.find(params[:venue_id])
    else
      Court.find(params[:court_id]).venue
    end
  end

  def use_timezone
    venue = @venue || @game_pass.venue
    Time.use_zone(venue.timezone) { yield }
  end

  def game_pass_params
    params.require(:game_pass).permit(
      :name,
      :user_id,
      :court_type,
      :start_date,
      :end_date,
      :price,
      :total_charges,
      :remaining_charges,
      :active,
      court_sports: [],
      time_limitations: [:from, :to, weekdays: []],
    )
  end

  def create_game_pass_params
    game_pass_params.merge(
      active: true,
      venue_id: params[:venue_id],
      remaining_charges: params[:game_pass][:total_charges]
    )
  end

  def update_game_pass_params
    if params[:mark_as_paid].present?
      game_pass_params.merge(is_paid: true)
    else
      game_pass_params
    end
  end
end
