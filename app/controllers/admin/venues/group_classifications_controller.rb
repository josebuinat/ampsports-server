class Admin::Venues::GroupClassificationsController < Admin::BaseController
  def index
    @group_classifications = authorized_scope(venue.group_classifications).
                                  includes(:groups, :participation_credits)

    @group_classifications = @group_classifications.sort_on(params[:sort_on]) if params[:sort_on].present?
    @group_classifications = @group_classifications.paginate(page: params[:page])
  end

  def show
    group_classification
  end

  def create
    @group_classification = authorize venue.group_classifications.build(create_params)

    if @group_classification.save
      render 'show', status: :created
    else
      render json: { errors: @group_classification.errors }, status: :unprocessable_entity
    end
  end

  def update
    if group_classification.update(update_params)
      render 'show'
    else
      render json: { errors: @group_classification.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if group_classification.deletable? && group_classification.destroy
      render json: [group_classification.id]
    else
      head :unprocessable_entity
    end
  end

  def destroy_many
    deleted = many_group_classifications.select do |group_classification|
      group_classification.deletable? && group_classification.destroy
    end

    render json: deleted.map(&:id)
  end

  def select_options
    render json: (authorized_scope(venue.group_classifications).map do |classification|
      {
        value: classification.id,
        label: classification.name,
      }
    end)

  end

  private

  def company
    current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end

  def group_classification
    @group_classification ||= authorized_scope(venue.group_classifications).find(params[:id])
  end

  def many_group_classifications
    @many_group_classifications ||= authorized_scope(venue.group_classifications).
                                          where(id: params[:group_classification_ids])
  end

  def create_params
    params.require(:group_classification).permit(:name, :price, :price_policy)
  end

  def update_params
    create_params
  end
end
