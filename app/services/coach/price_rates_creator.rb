class Coach::PriceRatesCreator
  def initialize(coach, venue, admin, params)
    @coach = coach
    @venue = venue
    @admin = admin
    @price_rates_params = sanitize_price_rates(params)
  end

  def create_price_rates
    Time.use_zone(@venue.timezone) do
      @price_rates = build_price_rates
      return nil unless @price_rates.any?
      commit_price_rates
      return nil unless created?

      @price_rates
    end
  end

  def build_price_rates
    @price_rates_params.map do |price_rate_params|
      @coach.price_rates.build(price_rate_params)
    end
  end

  def created?
    @price_rates.none? { |price_rate| price_rate.errors.any? } && @price_rates.all?(&:persisted?)
  end

  def errors
    @price_rates.map do |price_rate|
      if price_rate.errors.any?
        { price_rate.name => price_rate.errors.messages }
      end
    end.compact
  end

  private

  def commit_price_rates
    Coach::PriceRate.transaction do
      # try to save all of them
      # we want to gather as much data about conflicts as possible
      @price_rates.each(&:save)

      raise ActiveRecord::Rollback unless created?
    end
  end

  def sanitize_price_rates(params)
    created_by = "#{@admin.class.name} #{@admin.full_name}"

    params.permit(times: [:start_time, :end_time])[:times].map do |times|
      {
        sport_name: params[:sport_name],
        rate: params[:rate],
        start_time: TimeSanitizer.input(times[:start_time]),
        end_time: TimeSanitizer.input(times[:end_time]),
        venue: @venue,
        created_by: created_by
      }
    end
  end
end
