# prepare time params

class MembershipTimeSanitizer
  def initialize(membership_params)
    @params = membership_params
    @weekday = @params[:weekday].to_s.capitalize

    if !Date::DAYNAMES.include?(@weekday)
      @weekday = membership_start_time && membership_start_time.in_time_zone.strftime('%A')
    end
  end

  # time params in UTC
  def time_params
    {
      membership_start_time: membership_start_time,
      membership_end_time: membership_end_time,
      start_time: reservations_start_time,
      end_time: reservations_end_time
    }
  end

  def membership_start_time
    # otherwise will return timeless date, which is not right
    return nil unless @params[:start_time].to_s.include?(':')

    @membership_start_time ||= TimeSanitizer.input(
      "#{@params[:start_date]} #{@params[:start_time]}"
    )
  end

  def membership_end_time
    # otherwise will return timeless date, which is not right
    return nil unless @params[:end_time].to_s.include?(':')

    @membership_end_time ||= TimeSanitizer.input(
      "#{@params[:end_date]} #{@params[:end_time]}"
    )
  end

  def reservations_start_time
    return nil if membership_start_time.nil?
    return @reservations_start_time if @reservations_start_time
    # time manipulations must be in time zone to preserve reservation hour through dst
    start = membership_start_time.in_time_zone
    @reservations_start_time = step_to_weekday(start).utc
  end

  def reservations_end_time
    return nil if reservations_start_time.nil?
    @reservations_end_time ||= TimeSanitizer.input(
      "#{reservations_start_time.in_time_zone.to_s(:date)} #{@params[:end_time]}"
    )
  end

  def last_reservation_start_time
    # time manipulations must be in time zone to preserve reservation hour through dst
    start = TimeSanitizer.input(@params[:start_time] + ' ' + @params[:end_date]).in_time_zone
    return nil if start.nil?
    step_back_to_weekday(start)
  end

  private

  def step_to_weekday(datetime)
    while datetime.strftime('%A') != @weekday
      datetime = datetime.advance(days: 1)
    end
    datetime
  end

  def step_back_to_weekday(datetime)
    while datetime.strftime('%A') != @weekday
      datetime = datetime.advance(days: -1)
    end
    datetime
  end
end
