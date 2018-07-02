# Handles validating reservations
module ReservationValidator
  extend ActiveSupport::Concern

  MINUTE_DURATIONS = [-1, 30, 60, 120].freeze

  included do
    # used to bypass some validations for admin
    attr_accessor :update_by_admin

    validates :user, presence: true,
                     associated: true
    validates :court, presence: true, associated: true
    validates :price, numericality: { greater_than_or_equal_to: 0 },
                      allow_nil: false, presence: true
    validates :start_time, presence: true
    validates :end_time, presence: true

    validate :timing_order
    validate :in_the_future, unless: :by_admin?
    validate :no_overlapping_reservations
    validate :not_on_holiday
    validate :duration_policy, unless: :by_admin?
    validate :start_time_policy, unless: :by_admin?
    validate :date_limit_policy, unless: :by_admin?
    validate :court_active
    validate :booking_limits, unless: :by_admin?
    validate :coach_availability, if: :coached_session_changed?
  end

  def by_admin?
    admin? || update_by_admin
  end

  def timeslot_changed?
    start_time_changed? || end_time_changed? || court_id_changed?
  end

  # same as timeslot_changed? but ensures that it changed from the existing ones.
  # Why: due to callback hell reservation re-saves many times, but start_time_was = nil
  # for reservations which were initialized with #new. Hence, timeslot is changed code-wise
  # but from it should not be feature-wise.
  # def timeslot_changed_not_from_nil?
  #   (start_time_changed? && start_time_was.present?) ||
  #     (end_time_changed? && end_time_was.present?) ||
  #     (court_id_changed? && court_id_was.present?)
  # end

  def coached_session_changed?
    coach_connections.any? && timeslot_changed?
  end

  def timing_order
    return unless start_time.present? && end_time.present?

    unless end_time > start_time
      errors.add(:end_time, I18n.t('errors.reservation.end_time.timing_order'))
    end
  end

  def in_the_future
    return unless start_time.present? && court.present?

    in_venue_tz do
      if changed? && start_time < Time.current.utc
        errors.add(:start_time, I18n.t('errors.reservation.start_time.in_the_future'))
      end
    end
  end

  def court_active
    return unless court.present?

    errors.add(:court,
               I18n.t('errors.reservation.court.closed')) unless court.active?
  end


  def no_overlapping_reservations
    return unless start_time.present? && end_time.present? && court.present?

    overlapping_reservations = get_overlapping_reservations
    if overlapping_reservations.any?
      full_name = overlapping_reservations.first.user.full_name
      errors.add(:overlapping_reservation, I18n.t('errors.reservation.overlapping', user_name: full_name.humanize))
    end
  end

  def not_on_holiday
    return unless start_time.present? && end_time.present? && court.present?
    #return if membership?

    in_venue_tz do
      unless court.working?(start_time, end_time)
        errors.add('Court', I18n.t('errors.reservation.court.closed'))
        return false
      end
    end
    true
  end

  def duration_policy
    return unless start_time.present? && end_time.present? && court.present?

    if duration.to_i < Court.duration_policies[court.duration_policy].to_i
      errors.add(:duration_policy, I18n.t('errors.reservation.end_time.duration_problem'))
    end
  end

  def start_time_policy
    return unless start_time.present? && court.present?
    return if membership?

    case court.start_time_policy.to_sym
    when :hour_mark
      if start_time.min != 0
        errors.add(:start_time, I18n.t('errors.reservation.start_time.zero'))
      end
    when :half_hour_mark
      if start_time.min != 30
        errors.add(:start_time, I18n.t('errors.reservation.start_time.half'))
      end
    when :quarter_hour_mark
      if (start_time.min != 15 && start_time.min != 45)
        errors.add(:start_time, I18n.t('errors.reservation.start_time.quarter'))
      end
    else
      true
    end
  end

  def date_limit_policy
    return unless start_time.present? && court.present?
    return if membership?

    in_venue_tz do
      unless court.venue.bookable?(start_time.to_date)
        errors.add(:start_time,
                   I18n.t('errors.reservation.start_time.days_in_advance',
                          limit: court.venue.booking_ahead_limit))
      end
    end
  end

  def booking_limits
    return unless start_time.present? && end_time.present? && court.present?
    return if membership?

    validate_consecutive_bookable_hours
    validate_bookable_hours_per_day
  end

  def validate_consecutive_bookable_hours
    max_hours = venue.max_consecutive_bookable_hours.to_i
    return unless max_hours > 0

    consecutive_hours = consecutive_hours(user_reservations_within(max_hours))

    if consecutive_hours > max_hours
      errors.add(:end_time,
                  I18n.t('errors.reservation.end_time.max_consecutive_hours',
                    expected: max_hours, given: consecutive_hours))
    end
  end

  def validate_bookable_hours_per_day
    max_hours = venue.max_bookable_hours_per_day.to_i
    return unless max_hours > 0

    same_day_hours = (hours + same_day_reservations.to_a.sum(&:hours)).to_i

    if same_day_hours > max_hours
      errors.add(:end_time,
                  I18n.t('errors.reservation.end_time.max_hours_per_day',
                    expected: max_hours, given: same_day_hours))
    end
  end

  def consecutive_hours(reservations)
    (reservations.to_a + [self]).
      sort_by(&:start_time).
      chunk_while { |prev, nxt| prev[:end_time] == nxt[:start_time] }.
      map{ |chunk| chunk.sum(&:hours) }.
      max.
      to_i
  end

  def user_reservations_within(max_hours)
    minutes_margin = max_hours * 60 - duration.ceil
    Reservation.for_venue(venue).
                where(user: user).
                where('end_time >= ? AND start_time <= ?',
                        start_time.advance(minutes: -minutes_margin),
                        end_time.advance(minutes: minutes_margin))
  end

  def same_day_reservations
    # let's be sure we find reservations in venue zone day and not of admin
    in_venue_tz do
      venue_local_time = TimeSanitizer.output(start_time)
      beginning_of_day = venue_local_time.beginning_of_day.utc
      end_of_day = venue_local_time.end_of_day.utc

      Reservation.for_venue(venue).
                  where(user: user).
                  between(beginning_of_day, end_of_day)
    end
  end

  def coach_availability
    coach_connections.each do |connection|
      unless connection.coach.available?(court, start_time, end_time, id)
        errors.add(:coach_ids, I18n.t('errors.coach.unavailable',
                                        name: connection.coach.full_name))
      end
    end
  end

  def in_venue_tz
    Time.use_zone(venue.timezone) { yield }
  end
end
