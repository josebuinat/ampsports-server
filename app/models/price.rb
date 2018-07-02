require 'interval_breaker'

# Represents court pricing rules
class Price < ActiveRecord::Base
  include WeeklyScheduled
  include Conflicts

  has_many :dividers, dependent: :destroy
  has_many :courts, through: :dividers

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :minimum_price

  def duplicate
    Price.new(
      price: self.price,
      start_time: self.start_time,
      end_time: self.end_time,
      monday: self.monday,
      tuesday: self.tuesday,
      wednesday: self.wednesday,
      thursday: self.thursday,
      friday: self.friday,
      saturday: self.saturday,
      sunday: self.sunday
    )
  end

  def duplicate!
    dup = duplicate
    dup.save!
    dup
  end

  def update_start_and_end_minutes_of_a_day(start, _end)
    self.update_attributes(
      start_minute_of_a_day: start,
      end_minute_of_a_day: _end
    )
  end

  def assign_start_and_end_minutes_of_a_day(start, _end)
    self.assign_attributes(
      start_minute_of_a_day: start,
      end_minute_of_a_day: _end
    )
  end

  def set_weekdays(days)
    self.weekdays = days
  end

  def set_weekdays!(days)
    set_weekdays(days)
    self.save!
  end

  def find_conflicts(another_price)
    {
      days: self.weekdays & another_price.weekdays,
      court_ids: self.court_ids & another_price.court_ids,
      conflicting_interval: IntervalBreaker.conflicting_interval(
        [self.start_minute_of_a_day, self.end_minute_of_a_day],
        [another_price.start_minute_of_a_day, another_price.end_minute_of_a_day]
      )
    }
  end

  def merge_price!(another, *courts)
    court_ids = courts.map(&:id)
    self.dividers.where(court_id: court_ids).destroy_all

    unaffected_weekdays = self.weekdays - another.weekdays
    if unaffected_weekdays.any?
      dup = self.duplicate!
      dup.set_weekdays!(unaffected_weekdays)
      courts.each do |court|
        Divider.create(price: dup, court: court)
      end
    end

    breakdown = IntervalBreaker.break(
      [self.start_minute_of_a_day, self.end_minute_of_a_day],
      [another.start_minute_of_a_day, another.end_minute_of_a_day]
    )

    affected_weekdays = self.weekdays & another.weekdays
    breakdown.each do |time_pair|
      dup = self.duplicate!
      dup.assign_start_and_end_minutes_of_a_day(*time_pair)
      dup.set_weekdays!(affected_weekdays)
      courts.each do |court|
        Divider.create(price: dup, court: court)
      end
    end

    # process with wednesday
    courts.each do |court|
      Divider.create(price: another, court: court)
    end
  end

  # if applies to some part of timeslot, then return calculated price for this part, or zero
  def apply(start_time, end_time)
    start_minute = TimeSanitizer.output(start_time).minute_of_a_day
    end_minute = TimeSanitizer.output(end_time).minute_of_a_day
    day = TimeSanitizer.output(start_time).strftime('%A').to_s.downcase.to_sym

    if applies_to?(start_minute, end_minute, day)
      starts = start_minute_of_a_day > start_minute ? start_minute_of_a_day : start_minute
      ends = end_minute_of_a_day < end_minute ? end_minute_of_a_day : end_minute

      (ends - starts) * price / 60
    else
      0.0
    end
  end

  def applies_to?(start_minute, end_minute, day)
    self[day] == true &&
      start_minute_of_a_day < end_minute &&
      end_minute_of_a_day > start_minute
  end

  def dows
    WEEKDAYS.each_with_index
            .map { |wd, idx| send(wd) ? idx : -1 }.select { |dow| dow >= 0 }
  end

  def days=(value)
    # filter because we want to return values we set
    sym_values = value.map(&:to_sym)
    WEEKDAYS.select { |weekday| public_send("#{weekday}=", sym_values.include?(weekday)) }
  end

  def days
    WEEKDAYS.select { |weekday| public_send(weekday) }
  end

  protected

  def minimum_price
    court = courts.first
    # all courts have same country within venue, we can chack only one
    if court && price && court.country.US? && price < 2
      errors.add(:price, I18n.t('errors.price.minimum'))
    end
  end
end
