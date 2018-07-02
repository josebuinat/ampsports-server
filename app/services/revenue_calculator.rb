class RevenueCalculator
  def initialize(company, venue_id, start_date, end_date, sport_name = nil)
    @company = company
    @venue_id = venue_id.nil? ? @company.venue_ids : venue_id.to_i
    @start_date = Date.parse(start_date)
    @end_date = Date.parse(end_date)
    @sport_name = Court.sport_names[sport_name]
  end

  def call
    from = @start_date.beginning_of_day
    to = @end_date.end_of_day
    @related_reservations = Reservation.
      # maybe not updated_at, but stars_at, needs deep thinking.
      # used updated_at instead of created_at to value amount_paid
      # (but obviously this does not do what we want to)
      where('reservations.start_time between ? and ?', from, to).
      joins(:court).
      where(courts: { venue_id: @venue_id })

    if @sport_name
      @related_reservations = @related_reservations.where(courts: { sport_name: @sport_name })
    end

    self
  end

  def reservations_count
    @related_reservations.count
  end

  def total
    @total ||= @related_reservations.sum(:price)
  end

  def chunks
    # this is slow, if logic is correct rewrite it to an appropriate SQL
    @chunks ||= @related_reservations.group_by(&:price).transform_values! do |reservations|
      reservations.reduce(0) { |sum, x| sum + x.price.to_i }
    end.delete_if { |price, amount_paid| amount_paid.zero? }
  end

end