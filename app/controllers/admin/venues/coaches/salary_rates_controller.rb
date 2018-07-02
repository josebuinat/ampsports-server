class Admin::Venues::Coaches::SalaryRatesController < Admin::BaseController
  wrap_parameters Coach::SalaryRate # throws error otherwise. Do we need wrap_parameters at all?
  around_action :use_timezone

  def index
    @salary_rates = authorized_scope(coach.salary_rates).
                          for_venue(venue).
                          for_sport(params[:sport])
  end

  def show
    salary_rate
  end

  def update
    if salary_rate.update(update_params)
      render 'show'
    else
      render json: { errors: salary_rate.errors }, status: :unprocessable_entity
    end
  end

  def create
    @salary_rate = authorize coach.salary_rates.build(create_params)

    if @salary_rate.save
      render 'show', status: :created
    else
      render json: { errors: @salary_rate.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    salary_rate.destroy

    render json: [salary_rate.id]
  end

  def destroy_many
    deleted = many_salary_rates.select do |salary_rate|
      salary_rate.destroy
    end

    render json: deleted.map(&:id)
  end

  private

  def update_params
    params.require(:salary_rate).
           permit(:start_time, :end_time, :sport_name, :rate, weekdays: [])
  end

  def create_params
    update_params.merge(
      venue: venue,
      created_by: "#{current_admin.class.name} #{current_admin.full_name}"
    )
  end

  def salary_rate
    @salary_rate ||= authorized_scope(coach.salary_rates).for_venue(venue).find(params[:id])
  end

  def many_salary_rates
    @many_salary_rates ||= authorized_scope(coach.salary_rates).
                                    for_venue(venue).
                                    where(id: params[:salary_rate_ids])
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
