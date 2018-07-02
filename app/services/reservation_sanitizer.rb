# Sanitize JSON booking params into reservations
class ReservationSanitizer
  def initialize(user, params)
    @user = user
    @duration = params[:duration].to_i
    @pay = params[:pay].present?
    @token = params[:card].to_s
    @bookings = sanitize_bookings(params[:bookings])
  end

  # Returns a list of created reservations or nil
  def create_reservations
    Time.use_zone(@timezone) do
      @reservations = build_reservations
      return nil unless @reservations.any?
      @reservations = commit_reservations(@reservations)
      return nil unless valid? && @reservations.all?(&:persisted?)
      charge(@reservations) && @reservations.each(&:reload) if @pay
      track(@reservations)

      @reservations
    end
  end

  # Returns a list of built reservations
  def build_reservations
    # IMPORTANT: .take_matching_resell should be called before validations
    reservations = @bookings.map { |booking| Reservation.new(booking).take_matching_resell }
    all_valid = reservations.all? { |reservation| reservation.valid? }
    all_valid ? group_bookings.map { |booking| Reservation.new(booking).take_matching_resell } : reservations
  end

  def valid?
    @reservations.none? { |reservation| reservation.errors.any? }
  end

  def errors
    @reservations.map do |reservation|
      if reservation.errors.any?
        [reservation.name, reservation.errors.full_messages]
      end
    end.compact.to_h
  end

  def group_bookings
    merge_bookings = -> (chunk) do
      total = chunk.sum { |b| b[:price] }
      chunk.first.tap do |result|
        result[:price] = total
        result[:end_time] = chunk.last[:end_time]
      end
    end
    grouped_by_court = @bookings.group_by { |booking| booking[:court_id] }
    grouped_by_court.values.map do |group|
      group.
        sort_by { |booking| booking[:start_time] }.
        chunk_while { |prv, nxt| prv[:end_time] == nxt[:start_time] }.
        map { |chunk| merge_bookings.call(chunk) }
    end.flatten
  end

  private

  def sanitize_bookings(bookings)
    bookings = JSON.parse(bookings) rescue []
    @court_cache = build_court_cache(bookings)

    bookings.map do |booking|
      sanitize_booking(booking)
    end
  end

  def build_court_cache(bookings)
    court_ids = bookings.map{ |booking| booking['id'].to_i }.uniq
    Court.where(id: court_ids).includes(:venue).to_a
  end

  def get_court_from_cache(booking)
    court_id = booking['id'] = booking['id'].to_i
    @court_cache.find{ |court| court.id == court_id }
  end

  def get_time_zone_from_court(court)
    return Time.zone if court.blank?
    venue = court.venue
    return Time.zone if venue.blank?
    venue.timezone ? venue.timezone : Time.zone
  end

  def sanitize_booking(booking)
    court = get_court_from_cache(booking)
    @timezone = get_time_zone_from_court(court)

    Time.use_zone(@timezone) do
      start_time = parse_start_time(booking)
      end_time = calculate_end_time(start_time, booking)
      price = calculate_price(court, start_time, end_time)
      {
        user: @user,
        start_time: start_time,
        end_time: end_time,
        court_id: booking['id'],
        price: price,
        game_pass_id: @pay ? booking['game_pass_id'] : nil,
        booking_type: :online,
        payment_type: :unpaid
      }
    end
  end

  def commit_reservations(reservations)
    Reservation.transaction do
      reservations = reservations.map do |reservation|
        reservation.save!
        reservation.court.venue.add_customer(@user, track_with_actor: @user)
        reservation
      end
    end
  rescue
    reservations
  end

  def charge(reservations)
    reservations.map do |reservation|
      # can be already paid with game pass
      reservation.charge(@token) unless reservation.paid?
    end
  end

  def track(reservations)
    # track only if all reservations succesfully saved
    reservations.each do |reservation|
      reservation.track_booking
    end
    ActivityLog.record_log(:reservation_created, reservations.first.company.id, @user, reservations)
  end

  def parse_start_time(booking)
    TimeSanitizer.input(booking['start_time'].to_s) rescue nil
  end

  def calculate_end_time(start_time, booking)
    return nil if start_time.blank?

    start_time + (booking['duration'].to_i > 0 ? booking['duration'].to_i : @duration).minutes
  end

  def calculate_price(court, start_time, end_time)
    return nil if court.blank? || start_time.blank? || end_time.blank?
    discount = @user && @user.discount_for(court, start_time, end_time)

    court.price_at(start_time, end_time, discount)
  end
end
