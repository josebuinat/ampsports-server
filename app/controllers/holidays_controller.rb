class HolidaysController < ApplicationController
  def create
    holiday = Holiday.new(holiday_params)
    timezone = get_timezone(holiday)
    Time.use_zone(timezone) do
      parse_dates!(holiday)
      if holiday.save
        conflicting = find_conflicting(holiday)
        render json: { holiday: holiday, conflicting: conflicting}, status: :ok
      else
        render json: holiday, status: 400
      end
    end
  end

  def handle_conflicting
    holiday = Holiday.find(params[:holiday_id])
    if params[:cancel_conflicting]
      cancelled = find_conflicting(holiday).select do |reservation|
        reservation.cancel(current_admin)
      end
      ActivityLog.record_log(:reservation_cancelled, cancelled.first.company.id, current_admin, cancelled)
      head :ok
    else
      holiday.destroy
      render json: I18n.t('venues.holidays_new.create_cancelled'), status: :ok
    end
  end

  def destroy
    @holiday = Holiday.find(params[:id]).destroy
    render json: @holiday, status: :ok
  end

  private

  def get_timezone(holiday)
    court = Court.find(holiday.court_ids.first)
    court.venue.timezone
  end

  def parse_dates!(holiday)
    _params = params[:holiday]
    start_time = "#{_params[:start_date]} #{_params[:start_time]}"
    end_time = "#{_params[:end_date]} #{_params[:end_time]}"

    holiday.start_time = TimeSanitizer.input(start_time)
    holiday.end_time = TimeSanitizer.input(end_time)
  end

  def find_conflicting(holiday)
    Reservation.where('start_time BETWEEN :start AND :end OR end_time BETWEEN :start AND :end',
                      start: holiday.start_time,
                      end: holiday.end_time)
               .where(court_id: holiday.court_ids)
  end

  def holiday_params
    params.require(:holiday).permit(:start_time, :end_time, court_ids: [])
  end
end
