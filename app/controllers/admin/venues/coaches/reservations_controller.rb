class Admin::Venues::Coaches::ReservationsController < Admin::BaseController
  around_action :use_timezone

  # action for coach calendar
  # it have to return:
  #   - coached reservations from all company venues
  #     shuld include court_id and related courts json
  #     (from other venues or sports they will be grayed out on calendar)
  #   - unavailable slots, when all of this venue courts are booked
  def index
    # regular reservations for coaching PLUS reservations owned by the coach;
    # owned reservations shall be on this calendar as well
    @reservations = authorized_scope(company.reservations, nil, ::Coach::ReservationPolicy).
                            where(venues: { id: venue.id }).
                            for_coach(coach).
                            overlapping(start_time, end_time).includes(:user)

    @reservations = @reservations.for_sport(params[:sport]) if params[:sport].present?
    # stuff for normalized json
    @courts = company.courts.
                      where(id: @reservations.map(&:court_id).uniq).
                      includes(:shared_courts)
  end

  def unavailable_slots
    @unavailable_slots = venue.unavailable_slots(params[:sport], start_time, end_time, params[:coach_id])
    # also, we need to attach reservations from OTHER venues which belong to this coach
    # (they are unavailable because coach can be only at 1 place at a time, hence we
    # have to block that time because he is busy)
    from_other_venues = authorized_scope(company.reservations, nil, ::Coach::ReservationPolicy).
                                where.not(venues: { id: venue.id }).
                                for_coach(coach).
                                pluck(:start_time, :end_time).
                                map { |r| { start: r[0], end: r[1] } }

    @unavailable_slots.concat(from_other_venues)
  end



  private

  def start_time
    @start_time ||= TimeSanitizer.output_input(params[:start]).beginning_of_day
  end

  def end_time
    @end_time ||= TimeSanitizer.output_input(params[:end]).end_of_day
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
