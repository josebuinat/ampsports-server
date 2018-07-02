class API::CourtsController < API::BaseController
  def types
    court_types = GamePass.court_types.keys.map do |type|
      { value: type, label: GamePass.human_attribute_name(type) }
    end
    render json: court_types
  end

  def reservations
    if params[:court_id]
      court = Court.find(params[:court_id])
      reservations = Reservation.where(court: court)
      venue = court.venue
    else
      venue = Venue.find(params[:venue_id])
      reservations = venue.reservations
    end
    @current_company = venue.company
    @timezone = venue.timezone
    Time.use_zone(@timezone) do
      start_time = TimeSanitizer.input(params[:date])
      from = start_time.beginning_of_day
      to = start_time.end_of_day
      @reservations = reservations.
        where(Reservation.arel_table[:start_time].gteq(from)).
        where(Reservation.arel_table[:start_time].lteq(to))
    end
  end

  def surfaces
    court_surfaces = Court.surfaces.keys.map do |surface|
      { value: surface, label: Court.human_attribute_name(surface) }
    end
    render json: court_surfaces
  end
end
