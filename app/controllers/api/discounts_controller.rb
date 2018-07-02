class API::DiscountsController < API::BaseController
  before_action :authenticate_admin!
  before_action :set_venue, only: [:create]
  before_action :set_discount, only: [:show, :update]
  around_action :use_timezone, only: [:create, :show, :update]

  def create
    discount = @venue.discounts.new(discount_params)
    if discount.save
      render json: 'success', status: 201
    else
      render json: discount.errors.full_messages, status: :unprocessable_entity
    end
  end

  def show
    render json: @discount
  end

  def update
    @discount.assign_attributes(discount_params)
    if @discount.save
      render json: 'success', status: 204
    else
      render json: @discount.errors.full_messages, status: :unprocessable_entity
    end
  end

  private

  def set_venue
    @venue = Venue.find(params[:venue_id])
  end

  def set_discount
    @discount = Discount.find(params[:id])
  end

  def use_timezone
    venue = @venue || @discount.venue
    if venue
      Time.use_zone(venue.timezone) { yield }
    else
      yield
    end
  end

  def discount_params
    params.require(:discount).permit(
                                    :name,
                                    :value,
                                    :method,
                                    :round,
                                    :court_type,
                                    :start_date,
                                    :end_date,
                                    time_limitations: [:from, :to, weekdays: []],
                                    court_sports: [],
                                    court_surfaces: []
    )
  end
end
