# Represents company coaches with restricted admin functionality
class Coach < ActiveRecord::Base
  include AdminAndCoachShared
  include ClockType
  include AdminPermissions
  include Sortable
  virtual_sorting_columns({
    full_name: {
      order: ->(direction) { "coaches.first_name #{direction}, coaches.last_name #{direction}" }
    }
  })

  has_many :salary_rates, dependent: :destroy, class_name: 'Coach::SalaryRate'
  has_many :price_rates, dependent: :destroy, class_name: 'Coach::PriceRate'
  has_many :reservation_connections, class_name: 'Reservation::CoachConnection', dependent: :destroy
  has_many :reservations, through: :reservation_connections
  has_many :membership_connections, dependent: :destroy, class_name: 'Membership::CoachConnection'
  has_many :memberships, through: :membership_connections
  has_many :group_connections, class_name: 'Group::CoachConnection', dependent: :destroy
  has_many :groups, through: :group_connections
  has_many :owned_reservations, as: :user, class_name: 'Reservation', dependent: :destroy

  validates :experience, presence: true

  enum level: [:base, :editor, :manager]

  def devise_scope
    :admin
  end

  def god?
    false
  end

  def self.password_fields
    [:current_password, :password, :password_confirmation]
  end

  def price_at(start_time, end_time, court)
    price_rates.for_timeslot(court, start_time, end_time).map do |price|
      price.apply(start_time, end_time)
    end.sum
  end

  def sports
    self[:sports].to_s.split(',')
  end

  def sports=(raw_sports)
    sports = raw_sports.to_a.map(&:strip).map(&:downcase) & Court.sport_names.keys

    self[:sports] = sports.any? ? sports.join(',') : nil
  end

  def self.with_prices_for(court, start_time, end_time)
    where(id: Coach::PriceRate.for_timeslot(court, start_time, end_time).select(:coach_id))
  end

  # should have price rules covering whole timeslot
  def available?(court, start_time, end_time, for_reservation_id = nil)
    start_second = TimeSanitizer.output(start_time).to_i
    end_second = TimeSanitizer.output(end_time).to_i
    intersecting_rates_seconds = price_rates.
                                    for_timeslot(court, start_time, end_time).
                                    map(&:as_seconds)

    free?(start_time, end_time, for_reservation_id) &&
      MathExtras.subtract_ranges([(start_second..end_second)], intersecting_rates_seconds).none?
  end

  def free?(start_time, end_time, for_reservation_id = nil)
    sanitized_start_time = TimeSanitizer.output(start_time)
    sanitized_end_time = TimeSanitizer.output(end_time)

    reservations.where.not(id: for_reservation_id).
                 overlapping(sanitized_start_time, sanitized_end_time).
                 none?
  end

  def calculate_salary(court, start_time, end_time)
    start_minute = TimeSanitizer.output(start_time).minute_of_a_day
    end_minute = TimeSanitizer.output(end_time).minute_of_a_day
    weekday = TimeSanitizer.output(start_time).strftime('%A').to_s.downcase

    salary_rates.for_timeslot(court, start_minute, end_minute, weekday).
                  map { |salary_rate| salary_rate.apply(start_minute, end_minute, weekday) }.
                  sum
  end

end
