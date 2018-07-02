# Represents coaches price rates
class Coach::PriceRate < ActiveRecord::Base
  include SportNames
  include TimeSpreadable

  belongs_to :venue, required: true
  belongs_to :coach, required: true

  validates :sport_name, :start_time, :end_time, :rate, presence: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }
  validate  :validate_conflicts

  scope :for_venue, ->(venue) { where(venue: venue) }
  scope :between, ->(from, to) { where('start_time >= :from and end_time <= :to', from: from, to: to) }
  scope :for_timeslot, ->(court, start_time, end_time) do
    for_venue(court.venue).
      for_sport(court.sport_name).
      overlapping(start_time, end_time)
  end

  def conflicting_rates
    self.class.where(venue: venue, coach: coach, sport_name: sport_name_id).
      where.not(id: self.id).
      overlapping(start_time, end_time)
  end

  def name
    starts = TimeSanitizer.output(start_time).to_s(:date_time) rescue 'NA'
    ends = TimeSanitizer.output(end_time).to_s(:date_time) rescue 'NA'

    "#{starts} - #{ends}"
  end

  def as_seconds
    [
      TimeSanitizer.output(start_time).to_i,
      TimeSanitizer.output(end_time).to_i
    ]
  end

  def apply(start_time, end_time)
    return 0.0 unless appliable?(start_time, end_time)

    start_time = [start_time, self.start_time].max
    end_time = [end_time, self.end_time].min
    hours = (end_time - start_time) / 60
    hours * rate / 60
  end

  def appliable?(start_time, end_time)
    self.start_time <= end_time && self.end_time >= start_time
  end

  # Coach is unavailable when he has no availability (obviously)
  # This method returns an inversion of PriceRates, e.g.
  # if price rate are set for 30-50 (30 is start time, 50 is end time)
  # then this method returns [[0, 30], [50, 100]] (0 and 100 are arguments)
  def self.break_into_unavailable_times(price_rates, start_time, end_time)
    timespan_without_breaks = [[start_time, end_time]]

    # [[1, 100]]
    # [[1, 30], [30, 100]]
    price_rates.inject(timespan_without_breaks) do |sum, price_rate|
      sum.flat_map do |timespan|
        IntervalBreaker.break(timespan, [price_rate.start_time, price_rate.end_time])
      end
    end

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
