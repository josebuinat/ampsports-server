class Admin::Venues::DiscountsController < Admin::BaseController
  def index
    @discounts = authorized_scope(venue.discounts)
    @discounts = @discounts.search(params[:search]) if params[:search].present?
    @discounts = @discounts.sort_on(params[:sort_on]) if params[:sort_on].present?
    @discounts = @discounts.paginate(page: params[:page])
  end

  def show
    discount
  end

  def update
    if discount.update(update_params)
      render 'show'
    else
      render json: { errors: discount.errors }, status: :unprocessable_entity
    end
  end

  def create
    # cannot use venue.discounts.build here, as it would not associate it with the venue
    @discount = authorize venue.discounts.create(create_params)
    if @discount.persisted?
      render 'show', status: :created
    else
      render json: { errors: discount.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    discount.destroy
    render json: [discount.id]
  end

  def destroy_many
    deleted_ids = params.require(:discount_ids).select do |discount_id|
      authorized_scope(venue.discounts).find_by(id: discount_id)&.destroy
    end

    render json: deleted_ids
  end

  def remove_from_user
    venue # load venue
    @connection = DiscountConnection.find_by(user_id: user.id, discount_id: discount.id)
    @connection.destroy
    render 'admin/users/show'
  end

  def add_to_user
    venue # load venue
    @connection = DiscountConnection.create(user_id: user.id, discount_id: discount.id)
    if @connection.persisted?
      render 'admin/users/show'
    else
      render json: { errors: @connection.errors }, status: :unprocessable_entity
    end
  end

  def select_options
    @discounts = authorized_scope(venue.discounts)
    options = @discounts.map do |discount|
      { value: discount.id, label: discount.name }
    end
    render json: options
  end

  protected

  # scalar :court_sports, :court_surfaces is needed for a nil(empty) value
  def update_params
    params.require(:discount).permit(:name, :value, :method, :round,
      :sports, :court_type, :start_date, :end_date, :time_limitations,
      :court_sports, :court_surfaces, court_sports: [], court_surfaces: [],
      time_limitations: [:from, :to, weekdays: []])
  end

  def create_params
    update_params
  end

  def discount
    @discount ||= authorized_scope(venue.discounts).find(params[:id])
  end

  def user
    @user ||= company.users.find(params[:user_id])
  end

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end
end