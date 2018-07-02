class Admin::ReservationsController < Admin::BaseController
  around_action :use_timezone

  def future_reservations
    @reservations = reservations.future
    render 'index'
  end

  def reservations_between
    @reservations = reservations.between(sanitized_start_date, sanitized_end_date)
    render 'index'
  end

  def destroy_many
    reservations = authorized_scope(company.reservations).
                      where(id: params.require(:reservation_ids))
    deleted_reservations = reservations.select do |reservation|
      reservation.cancel(current_admin)
    end

    ActivityLog.record_log(:reservation_cancelled, company.id, current_admin, deleted_reservations)
    render json: deleted_reservations.map(&:id)
  end

  private

  def reservations
    @reservations = authorized_scope(Reservation).for_company(company)
    @reservations = @reservations.for_person(user_id, user_type) if user_id
    @reservations = @reservations.where(venues: { id: venue_id }) if venue_id
    @reservations
  end

  def company
    @company ||= current_admin.company
  end

  def user_id
    params[:user_id].presence
  end

  def user_type
    params[:user_type].presence || 'User'
  end

  def venue_id
    params[:venue_id].presence
  end

  def venue
    @venue ||= venue_id ? Venue.find(venue_id) : company.venues.first
  end

  def sanitized_end_date
    output_date = TimeSanitizer.output(params[:end_date]).end_of_day.to_s
    @sanitized_end_date ||= TimeSanitizer.input(output_date) rescue nil
  end

  def sanitized_start_date
    output_date = TimeSanitizer.output(params[:start_date]).beginning_of_day.to_s
    @sanitized_start_date ||= TimeSanitizer.input(output_date) rescue nil
  end

end
