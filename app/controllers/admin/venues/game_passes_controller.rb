class Admin::Venues::GamePassesController < Admin::BaseController
  around_action :use_timezone

  def index
    @game_passes = authorized_scope(venue.game_passes).not_templates.includes(:user, :coaches)
    @game_passes = @game_passes.search(params[:search]) if params[:search].present?
    @game_passes = @game_passes.sort_on(params[:sort_on]) if params[:sort_on].present?
    @game_passes = @game_passes.paginate(page: params[:page])
  end

  def show
    game_pass
  end

  def update
    if game_pass.update(update_params)
      make_template_if_needed
      render 'show'
    else
      render json: { errors: game_pass.errors }, status: :unprocessable_entity
    end
  end

  def create
    @game_pass = authorize venue.game_passes.build(create_params)
    if @game_pass.save
      make_template_if_needed
      render 'show', status: :created
    else
      render json: { errors: @game_pass.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    game_pass.destroy
    render json: [game_pass.id]
  end

  def destroy_many
    deleted = many_game_passes.select do |game_pass|
      game_pass.destroy
    end

    render json: deleted.map(&:id)
  end

  def available_for_select
    authorize GamePass

    user = User.find(params[:user_id])
    start_time = TimeSanitizer.input(params[:start_time].to_s)
    end_time = TimeSanitizer.input(params[:end_time].to_s)
    court = venue.courts.find(params[:court_id])
    coach_ids = params[:coach_ids].to_a.map(&:to_i)

    game_passes = user.available_game_passes(court, start_time, end_time, coach_ids).map do |game_pass|
      { value: game_pass.id,
        label: game_pass.auto_name,
        remaining_charges: game_pass.remaining_charges }
    end

    render json: game_passes
  end

  private

  def make_template_if_needed
    template_name = params.dig(:game_pass, :template_name)
    return if template_name.blank?
    template = game_pass.dup
    template.template_name = template_name
    template.user_id = nil
    template.save
  end

  # scalar :court_sports, :court_surfaces, :coach_ids is needed for a nil(empty) value
  def update_params
    params.require(:game_pass).permit(
      :name, :user_id, :court_type, :start_date, :end_date, :price,
      :total_charges, :remaining_charges, :active,
      :court_sports, :court_surfaces, :coach_ids,
      coach_ids: [], court_sports: [], court_surfaces: [],
      time_limitations: [:from, :to, weekdays: []],
    )
  end

  def create_params
    update_params
  end

  def game_pass
    @game_pass ||= authorized_scope(venue.game_passes).find(params[:id])
  end

  def many_game_passes
    @many_game_passes ||= authorized_scope(company.game_passes).
                            where(id: params[:game_pass_ids])
  end

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end
end
