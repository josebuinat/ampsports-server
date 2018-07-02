module VenueTimeFrames
  extend ActiveSupport::Concern

  def time_frames(duration, date = Date.current, include_past = false, step = 30)
    @time_frames ||= Hash.new { |h, k| h[k] = {} }
    duration = duration.to_i
    step = step.to_i >= 15 ? step.to_i : 30
    date = TimeSanitizer.output(date).to_date

    return @time_frames[duration][date] if @time_frames[duration][date]

    @time_frames[duration][date] = calculate_time_frames(
      opening_local(date),
      closing_local(date),
      duration.minutes,
      include_past,
      step
    )
  end

  def with_time_frames(duration, date = Date.current, &block)
    time_frames(duration, date).map(&block)
  end

  def calculate_time_frames(start_time, end_time, duration, include_past = false, step = 30)
    time_frames = []
    current_frame = TimeFrame.new(start_time, start_time + duration)

    while current_frame.starts < end_time
      time_frames << current_frame if include_past || current_frame.starts > Time.current
      current_frame = TimeFrame.new(current_frame.starts + step.minutes, current_frame.ends + step.minutes)
    end

    time_frames
  end
end
