class Admin::Venues::PricesController < Admin::BaseController
  around_action :use_timezone

  # action for price calendar
  def index
    @prices = authorized_scope(venue.prices).includes(:courts)
    if params[:day].present?
      day = params[:day].to_s
      raise WrongActionError unless Price::WEEKDAYS.map(&:to_s).include?(day)
      @prices = @prices.where("#{day}": true)
    end

    # TODO: filter ones by sport, so it doesn't render golf prices when looking for tennis

    @prices = @prices.uniq
  end

  def show
    price
  end

  def update
    # important: don't supply empty array to update_or_find_conflicts - it will wipe them out!
    # instead supply nil to indicate that there's no change to courts, use previous
    @errors, @conflicts = price.update_or_find_conflicts(update_params, courts_ids_or_nil)
    if @conflicts.present?
      render json: { conflicts: @conflicts }, status: :unprocessable_entity
    elsif @errors.present?
      render json: { errors: @errors }, status: :unprocessable_entity
    else
      render 'show'
    end
  end

  def create
    @price = authorize Price.new(create_params)
    if @price.save
      conflicts = []
      court_conflicts = {}

      courts.each do |c|
        div = Divider.new(price: @price, court: c)
        unless div.save
          conflicts << div.conflict_prices
          div.conflict_prices.each do |p|
            court_conflicts[p.id] ||= []
            court_conflicts[p.id] << c.id
          end
        end
      end

      if conflicts.any?
        @price.destroy
        @conflicts = conflicts.flatten.uniq
        @courts = courts
        @court_conflicts = court_conflicts

        render json: { conflicts: @conflicts }, status: :unprocessable_entity
      else
        render 'show', status: :created
      end
    else
      render json: { errors: @price.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    price.destroy
    render json: [price.id]
  end

  private

  def update_params
    create_params
  end

  def courts
    if params.dig(:price, :use_all_courts)
      venue.courts
    else
      venue.courts.where(id: params.dig(:price, :court_ids))
    end
  end

  def courts_ids_or_nil
    ids = courts.pluck(:id)
    ids.empty? ? nil : ids
  end

  def create_params
    params.require(:price).permit(:price, :start_time, :end_time, days: [])
  end

  def price
    @price ||= authorized_scope(venue.prices).find(params[:id])
  end

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end
end
