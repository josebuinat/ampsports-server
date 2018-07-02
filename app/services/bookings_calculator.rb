class BookingsCalculator
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
    @reservations = Reservation.
      where('reservations.start_time between ? and ?', from, to).
      joins(:court).
      where(courts: { venue_id: @venue_id })

    if @sport_name
      @reservations = @reservations.where(courts: {sport_name: @sport_name})
    end

    self
  end

  def unpaid_count
    @unpaid_count ||= @reservations.where('amount_paid = 0').count
  end

  def to_be_invoiced_count
    @to_be_invoiced_count ||= @reservations.invoiceable.count
  end

  def invoiced_count
    @invoiced_count ||= @reservations.where(
      billing_phase: Reservation.billing_phases[:billed],
      payment_type: Reservation.payment_types[:unpaid]
    ).count
  end

  def paid_on_site_count
    @paid_on_site_count ||= @reservations.where(charge_id: nil).count
  end

  def paid_on_reservation_count
    @paid_on_reservation_count ||= @reservations.where.not(charge_id: nil).count
  end

  def paid_on_site
    @paid_on_site = @reservations.where(charge_id: nil).sum(:amount_paid)
  end

  def paid_on_reservation
    @paid_on_reservation = @reservations.where.not(charge_id: nil).sum(:price)
  end

  def booked_by_admin_count
    @booked_by_admin_count ||= @reservations.where(booking_type: Reservation.booking_types[:admin]).count
  end

  def booked_by_user_count
    @booked_by_user_count ||= @reservations.where.not(booking_type: Reservation.booking_types[:admin]).count
  end

end