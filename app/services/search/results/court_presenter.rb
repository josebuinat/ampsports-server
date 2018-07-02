class Search::Results::CourtPresenter < SimpleDelegator
  attr_reader :lowest_price, :available_times

  def initialize(court, venue, search, user)
    super(court)
    @lowest_price = 1_000_000
    Time.use_zone(venue.timezone) do
      @available_times = court.available_times(search.duration, search.date)
      available_times.each do |time_frame|
        discount = user&.discount_for(court, time_frame.starts, time_frame.ends)
        time_frame.price = court.price_at(time_frame.starts, time_frame.ends, discount)
        @lowest_price = time_frame.price if time_frame.price < @lowest_price
      end
    end
    if @lowest_price == 1_000_000
      @lowest_price = 0
    end
  end

end
