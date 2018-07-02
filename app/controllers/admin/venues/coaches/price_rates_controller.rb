class Admin::Venues::Coaches::PriceRatesController < Admin::BaseController
  wrap_parameters Coach::PriceRate
  around_action :use_timezone

  def index
    sanitized_date = TimeSanitizer.output_input(params[:date])
    start_time = sanitized_date
    end_time = sanitized_date + 7.days

    @price_rates = authorized_scope(coach.price_rates).
                          for_venue(venue).
                          for_sport(params[:sport]).
                          overlapping(start_time, end_time)
  end

  def unavailable_times
    start_time = TimeSanitizer.output_input(params[:start]).beginning_of_day
    end_time = TimeSanitizer.output_input(params[:end]).end_of_day
    price_rates = authorized_scope(coach.price_rates).
      for_venue(venue).
      for_sport(params[:sport]).
      overlapping(start_time, end_time)


    @unavailable_times = Coach::PriceRate.break_into_unavailable_times(price_rates, start_time, end_time)
  end

  def show
    price_rate
  end

  def create
    @price_rate = authorize coach.price_rates.build(create_params)

    if @price_rate.save
      render 'show', status: :created
    else
      render json: { errors: @price_rate.errors }, status: :unprocessable_entity
    end
  end

  def create_many
    @creator = Coach::PriceRatesCreator.new(coach, venue, current_admin, params)
    authorize @creator.build_price_rates.first
    @creator.create_price_rates

    if @creator.created?
      render 'index', status: :created
    else
      render json: { errors: @creator.errors }, status: :unprocessable_entity
    end
  end

  def update
    if price_rate.update(update_params)
      render 'show'
    else
      render json: { errors: price_rate.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    price_rate.destroy

    render json: [price_rate.id]
  end

  def destroy_many
    deleted = many_price_rates.select do |price_rate|
      price_rate.destroy
    end

    render json: deleted.map(&:id)
  end

  private

  def update_params
    times = params.require(:price_rate).permit(:start_time, :end_time)
    params.require(:price_rate).permit(:sport_name, :rate).merge({
      start_time: TimeSanitizer.input(times[:start_time]),
      end_time: TimeSanitizer.input(times[:end_time]),
    })
  end

  def create_params
    update_params.merge(
      venue: venue,
      created_by: "#{current_admin.class.name} #{current_admin.full_name}"
    )
  end

  def price_rate
    @price_rate ||= authorized_scope(coach.price_rates).for_venue(venue).find(params[:id])
  end

  def many_price_rates
    @many_price_rates ||= authorized_scope(coach.price_rates).
                                    for_venue(venue).
                                    where(id: params[:price_rate_ids])
  end

  def coach
    @coach ||= company.coaches.find(params[:coach_id])
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end

  def company
    @company ||= current_admin.company
  end
end
