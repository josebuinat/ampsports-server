class Admin::Venues::GroupsController < Admin::BaseController
  around_action :use_timezone

  def index
    @groups = authorized_scope(venue.groups).base_includes

    @groups = @groups.search(params[:search]) if params[:search].present?
    @groups = @groups.sort_on(params[:sort_on]) if params[:sort_on].present?
    @groups = @groups.paginate(page: params[:page])
  end

  def show
    group
  end

  def create
    @group = authorize venue.groups.build(create_params)

    if @group.save
      render 'show', status: :created
    else
      render json: { errors: @group.errors }, status: :unprocessable_entity
    end
  end

  def update
    if group.update_with_seasons(group_params, seasons_params)
      render 'show'
    else
      render json: { errors: @group.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if group.destroy
      render json: [group.id]
    else
      head :unprocessable_entity
    end
  end

  def destroy_many
    deleted = many_groups.select do |group|
      group.destroy
    end

    render json: deleted.map(&:id)
  end

  def duplicate_many
    duplicated = many_groups.select do |group|
      group.create_duplicate
    end

    render json: duplicated.map(&:id)
  end

  def select_options
    render json: authorized_scope(venue.groups).
                    includes(:owner).
                    order(:owner_id, :created_at).
                    map { |group| { value: group.id,
                                    label: "#{group.name}" } }
  end

  private

  def company
    current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end

  def group
    @group ||= authorized_scope(venue.groups).find(params[:id])
  end

  def many_groups
    @many_groups ||= authorized_scope(venue.groups).where(id: params[:group_ids])
  end

  def group_params
    params.require(:group).permit(
      :classification_id,
      :name,
      :description,
      :participation_price,
      :max_participants,
      :priced_duration,
      :cancellation_policy,
      :coach_ids,
      :skill_levels,
      coach_ids: [],
      skill_levels: [],
    ).merge(
      owner: owner,
    )
  end

  def seasons_params
    params.require(:group).
      permit(seasons: [:id, :start_date, :end_date, :current, :participation_price, :_destroy]).
      dig(:seasons).to_a.tap do |seasons|
      # frontend may send `null` current values which is unacceptable due to indexes;
      # this dirty fix prevents that from happening
      seasons.each { |season| season[:current] ||= false }
    end
  end

  def create_params
    # explicit seasons building
    # seasons as nested attributes were conflicting with accepted_classification_ids
    # TODO: resolve conflict and use nested attributes
    seasons = seasons_params.map { |season| GroupSeason.new(season) }
    # Make sure we always have a current season; first one is current, others are not
    if seasons.present? && seasons.none?(&:current)
      seasons.each.with_index { |season, index| season.current = index.zero? }
    end
    group_params.merge(seasons: seasons)
  end

  def owner
    owner_id = params.dig(:group, :owner_id)
    owner_id.present? ? venue.users.find(owner_id) : current_admin
  end
end
