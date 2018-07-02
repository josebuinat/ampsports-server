# Represents coaches salary rates
class Coach::SalaryRate < ActiveRecord::Base
  include SportNames
  include WeeklyScheduled

  belongs_to :venue, required: true
  belongs_to :coach, required: true

  validates :sport_name, :rate, presence: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }
  validate  :validate_conflicts

  scope :for_venue, ->(venue) { where(venue: venue) }
  scope :for_timeslot, ->(court, start_minute, end_minute, weekday) do
    for_venue(court.venue).
      for_sport(court.sport_name).
      for_weekdays([weekday]).
      overlapping(start_minute, end_minute)
  end

  # if applies to some part of timeslot, then return calculated rate for this part, or zero
  def apply(start_minute, end_minute, weekday)
    if applies_to?(start_minute, end_minute, weekday)
      starts = start_minute_of_a_day > start_minute ? start_minute_of_a_day : start_minute
      ends = end_minute_of_a_day < end_minute ? end_minute_of_a_day : end_minute

      rate * (ends - starts) / 60
    else
      0.0.to_d
    end
  end

  def applies_to?(start_minute, end_minute, weekday)
    self[weekday.to_sym] &&
      start_minute_of_a_day <= end_minute &&
      end_minute_of_a_day >= start_minute
  end

  def conflicting_rates
    self.class.where(venue: venue, coach: coach, sport_name: sport_name_id).
      for_weekdays(weekdays).
      overlapping(start_minute_of_a_day, end_minute_of_a_day).
      where.not(id: self.id)
  end

  def name
    starts = TimeSanitizer.output(start_time).to_s(:date_time) rescue 'NA'
    ends = TimeSanitizer.output(end_time).to_s(:date_time) rescue 'NA'

    "#{starts} - #{ends}"
  end

  private

  def validate_conflicts
    return unless coach && venue

    if conflicting_rates.any?

      errors.add :start_time, :overlapping
      errors.add :conflicts, conflicting_rates.map(&:name)
    end
  end
end
