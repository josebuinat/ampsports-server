# Handles creation, update and destruction of recurrable reservations
module Recurrable
  extend ActiveSupport::Concern

  def make_reservations(time_params, court_ids)
    if court_ids.empty?
      errors.add(:court_ids, :blank)
      return
    end
    Time.use_zone(venue.timezone) do
      time_params = set_time_range(time_params)
      while time_params[:start_time].to_date <= time_params[:membership_end_time]
        court_ids.each do |court_id|
          create_reservation(court_id, time_params)
        end
        time_params = advance_time(time_params)
      end
    end
  end

  def handle_destroy
    Membership.transaction do
      destroy_future_reservations
      membership_connectors.delete_all
      destroy
    end
  end

  def handle_update(membership_params, time_params, court_ids)
    if court_ids.blank?
      errors.add(:court_ids, :blank)
      return false
    end

    assign_attributes(
      start_time: time_params[:membership_start_time],
      end_time: time_params[:membership_end_time],
      title: membership_params[:title],
      price: membership_params[:price],
      note: membership_params[:note],
      assigned_court_ids: court_ids.map(&:to_i)
      # We DO NOT update coaches. They are "frozen" at their creation state
    )
    commit_update(time_params, membership_params)
  end

  private

  def set_time_range(time_params)
    time_params.dup.tap do |params|
      start_time = params[:start_time]
      end_time = params[:membership_end_time]

      max_end_time = [end_time.to_date, start_time.to_date + 2.years].min

      new_end_time = end_time.change(
        day: max_end_time.day,
        month: max_end_time.month,
        year: max_end_time.year
      )

      params[:membership_end_time] = new_end_time
    end
  end

  # destroys unpaid future reservations starting from given time
  def destroy_future_reservations(time = Time.current.utc)
    destroy_reservations(time)
  end

  # destroys unpaid reservations for a specific time range
  def destroy_reservations(start_time, end_time = nil)
    unpaid_payment_type = Reservation.payment_types[:unpaid]
    reservations_to_destroy = self.reservations.where('payment_type = ? OR price = 0', unpaid_payment_type).
                                where(initial_membership_id: nil).
                                where('start_time > ?', start_time)
    if end_time.present?
      reservations_to_destroy = reservations_to_destroy.where('end_time < ?', end_time)
    end

    reservations_to_destroy.each(&:destroy)
    self.reservations.reload
  end

  def log_reservation(reservation)
    if logger.debug?
      logger.debug "#{reservation.start_time} #{reservation.end_time}"
      logger.debug reservation.valid?.to_s
      logger.debug reservation.errors.full_messages
    end
  end

  def advance_time(time_params)
    time_params[:start_time] = time_params[:start_time].in_time_zone.advance(days: 7)
    time_params[:end_time] = time_params[:end_time].in_time_zone.advance(days: 7)
    time_params
  end

  def create_reservation(court_id, time_params)
    if time_params[:start_time] >= Time.current.utc
      reservation = reservations.build(
        user: user,
        price: price,
        court_id: court_id,
        start_time: time_params[:start_time],
        end_time: time_params[:end_time],
        payment_type: :unpaid,
        booking_type: :membership,
        note: note,
        skip_booking_mail: true,
        coach_ids: coach_ids,
        # Heads up!!! If you ever will add participants (or coaches) to this list make sure
        # you test that you don't spam them (every reservation will mail participants and coaches on create)
        # Instead, you want to send only one email (with membership), not many emails (with reservations)
      )
      log_reservation(reservation)
      handle_overlapping_reservation(reservation)

      SegmentAnalytics.recurring_reservation(venue, reservation, user)
    end
  end

  def handle_overlapping_reservation(reservation)
    if self.ignore_overlapping_reservations && reservation.invalid? &&
      (reservation.errors.messages.count > 0)

      reservation.destroy
    end
  end

  def commit_update(time_params, membership_params)
    Time.use_zone(venue.timezone) do
      begin
        Membership.transaction do
          update_reservations(time_params)
          save!
        end
        true
      rescue ActiveRecord::RecordInvalid
        false
      end
    end
  end

  def update_reservations(time_params)
    time_params = set_time_range(time_params)
    destroy_future_reservations(time_params[:membership_end_time])
    destroy_reservations(Time.current.utc, time_params[:membership_start_time])

    while time_params[:start_time].to_date <= time_params[:membership_end_time]
      if time_params[:start_time] >= Time.current.utc
        start_time = TimeSanitizer.output(time_params[:start_time])
        current_week = TimeSanitizer.input(start_time.beginning_of_week.to_s)..TimeSanitizer.input(start_time.end_of_week.to_s)
        current_week_reservations = reservations.select { |r| current_week.include?(r.start_time) }
        court_mappings, to_be_added_courts = get_court_mappings(current_week_reservations.map(&:court_id))
        current_week_reservations.each do |reservation|
          # updates only unpaid reservations
          next if !reservation.unpaid? && reservation.price.positive?

          if court_mappings[reservation.court_id].present?
            # Heads up!!! If you ever will add participants (or coaches) to this list make sure
            # you test that you don't spam them (every reservation will mail participants and coaches on create)
            # Instead, you want to send only one email (with membership), not many emails (with reservations)
            reservation.assign_attributes(price: price,
                                          start_time: time_params[:start_time],
                                          end_time: time_params[:end_time],
                                          court_id: court_mappings[reservation.court_id],
                                          note: note,
                                          skip_booking_mail: true)
            handle_overlapping_reservation(reservation)
          else
            reservation.destroy
          end
        end

        to_be_added_courts.each do |court_id|
          create_reservation(court_id, time_params)
        end
      end

      time_params = advance_time(time_params)
    end
  end

  # returns array of court mappings (key: old court id, value: new court id) and
  #   new courts for new reservations
  # takes court ids for current reservations as argument
  def get_court_mappings(new_court_ids)
    unchanged = new_court_ids & assigned_court_ids
    old_courts = new_court_ids - assigned_court_ids
    new_courts = assigned_court_ids - new_court_ids

    mappings = Hash[old_courts.zip(new_courts) + unchanged.map{|i| [i, i]}]

    to_be_added_courts = new_courts - mappings.values

    [mappings, to_be_added_courts]
  end
end
