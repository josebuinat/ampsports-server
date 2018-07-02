class UnsoldCalculator
  def initialize(company, venue_id, start_date, end_date, sport_name = nil)
    @company = company
    @venue_id = venue_id.nil? ? @company.venue_ids : venue_id.to_i
    @start_date = Date.parse(start_date)
    @end_date = Date.parse(end_date)
    @sport_name = Court.sport_names[sport_name]
  end

  def call
    duration_in_days = (@end_date - @start_date).to_i
    @courts = Court.where(venue_id: @venue_id)
    if @sport_name
      @courts = Court.where(sport_name: @sport_name)
    end

    @hours_by_day = 0.upto(duration_in_days).map do |i|
      @courts.map do |court|
        missed_stuff_for_court(court, @start_date + i)
      end
    end

    self
  end

  def missed_stuff_for_court(court, date)
    available_times = court.available_times(court.minimum_duration, date, true)

    pointer = 100.years.ago
    distinct_times = available_times.select do |time|
      # available_times may give 6:00 - 7:00, 6:30 - 7:30, but it's not 2 hours free
      # remove those which are intersect from counting for better results
      next false if time.starts < pointer
      pointer = time.ends
      true
    end

    missed_profit = distinct_times.sum do |time|
      court.price_at(time.starts, time.ends)
    end

    missed_hours = distinct_times.sum(&:duration).to_f / 60

    {
      profit: missed_profit,
      hours: missed_hours,
    }
  end

  def summary
    @summary ||= @hours_by_day.flatten.reduce({profit: 0, hours: 0}) do |sum, data|
      sum[:profit] += data[:profit].to_f
      sum[:hours] += data[:hours].to_f
      sum
    end
  end
end
