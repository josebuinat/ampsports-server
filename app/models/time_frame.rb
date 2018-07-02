class TimeFrame
  attr_reader :starts, :ends
  attr_accessor :price

  def initialize(starts, ends)
    @starts = TimeSanitizer.output(starts)
    @ends = TimeSanitizer.output(ends)
  end

  def start_minute_of_day
    @start_minute_of_day ||= @starts.minute_of_a_day
  end

  def duration
    ((@ends - @starts) / 60).to_i
  end

  def to_key
    @key ||= @starts.to_s
  end

  def to_s
    "#{@starts} - #{@ends}"
  end

  def date
    # timeframes are always about the same date
    @date ||= @starts.to_date
  end
end
