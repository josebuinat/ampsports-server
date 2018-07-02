class UtilizationCalculator
  def initialize(company, venue_id, start_date, end_date, sport_name = nil)
    @company = company
    @venue_id = venue_id.nil? ? @company.venue_ids : [venue_id.to_i]
    @start_date = Date.parse(start_date)
    @end_date = Date.parse(end_date)
    @sport_name = Court.sport_names[sport_name]
  end

  def call
    duration_in_days = (@end_date - @start_date).to_i
    # if duration is 1 day, then going with chunks from start

    courts = Court.where(venue_id: @venue_id)
    courts = courts.where(sport_name: @sport_name) if @sport_name

    @by_day = 0.upto(duration_in_days).map do |i|
      day = @start_date + i
      utilization_for_courts = courts.map { |court| utilization_for(court, day) }.reject(&:empty?)
      next nil if utilization_for_courts.empty?
      flatten_utilization_for_courts(utilization_for_courts)
    end.compact

    self
  end

  def utilization_for(court, date)
    periods = time_periods(date, court.venue)
    last_time = periods.pop

    periods.map.with_index do |period, index|
      next_period = periods[index + 1] || last_time
      next nil unless court.has_price?(period, next_period)
      {
        from: period,
        to: next_period,
        availability: calculate_availability(court, period, next_period),
      }
    end.reject(&:nil?)
  end

  def value
    # by_day contains array of arrays; inner array contains hourly data (chunked to 2 hours)
    # for one day request we serve hourly data
    return @by_day.first if metrics == :hours
    flattened_days = @by_day.map { |day| flatten_day(day) }
    if metrics == :days
      # serve by days
      return flattened_days
    end

    # serve by weeks
    flattened_days.each_slice(7).map do |slice|
      flatten_day(slice)
    end
  end

  def total_availability
    flattened = @by_day.flatten
    flattened.map { |x| x[:availability] }.reduce(&:+).to_f / flattened.size
  end

  def metrics
    return :hours if @by_day.size <= 1
    return :days if @by_day.size <= 7
    :weeks
  end

  private

  def flatten_day(day)
    # important: thinks that (from - to) difference is always the same (2 hours).
    {
      from: day.first[:from],
      to: day.last[:to],
      availability: day.sum { |x| x[:availability] }.to_f / day.size
    }
  end


  def flatten_utilization_for_courts(array)
    # That's the bug: time_periods are no longer venue-based, every court has it's own time
    # pick the "longest" duration and count against it
    # array[0] - array of hashes for court 1
    # array[1] - array of hashes for court 2
    array.max_by(&:size).map.with_index do |utilization, index|
      {
        from: utilization[:from],
        to: utilization[:to],
        availability: array.reduce(0) do |sum, x|
          timeframe = x[index]
          availability = timeframe ? timeframe[:availability] : 1
          sum + availability
        end.to_f / array.size
      }
    end
  end

  def calculate_availability(court, from, to)
    # do not think that 30 minutes when it's impossible to use court as non-utilized
    from += 30.minutes unless court.can_start_at?(from)
    minimum_duration = court.minimum_duration.minutes
    available = (from.to_i...to.to_i).step(minimum_duration.to_i).map do |timestamp|
      time_frame = TimeFrame.new(Time.at(timestamp), Time.at(timestamp) + minimum_duration)
      is_taken = court.reserved_on?(time_frame) || court.shared_courts_reserved_on?(time_frame)
      !is_taken
    end

    available.count { |x| x }.to_f / available.count.to_f
  end

  def time_periods(date, venue)
    opening_local = venue.public_opening_local(date)
    closing_local = venue.public_closing_local(date)
    seconds_working_today = closing_local - opening_local

    current = 0
    chunks = []
    while current < seconds_working_today
      chunks.push(opening_local + current)
      current += 2.hours
    end
    chunks.push(closing_local)
  end
end