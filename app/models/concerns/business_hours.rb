# Handles venue opening and closing hours
module BusinessHours
  extend ActiveSupport::Concern

  DAYS = [:sun, :mon, :tue, :wed, :thu, :fri, :sat].freeze

  included do
    validates :business_hours, presence: true, unless: :hidden?
    validate :validate_business_hours, unless: :hidden?
  end

  def closing_hours
    closing_times = []
    7.times.each do |index|
      closing_times += daily_business_hours(index)
    end
    closing_times
  end

  def business_hours_ready?
    business_hours.each do |_, value|
      return false unless value[:opening] && value[:closing]
    end
    business_hours.keys.count == 7
  end

  def parse_business_hours(hours)
    self.business_hours = {
      mon: business_hours_pair(hours, :mon),
      tue: business_hours_pair(hours, :tue),
      wed: business_hours_pair(hours, :wed),
      thu: business_hours_pair(hours, :thu),
      fri: business_hours_pair(hours, :fri),
      sat: business_hours_pair(hours, :sat),
      sun: business_hours_pair(hours, :sun)
    }
  end

  def in_business?(start_time, end_time)
    start_time_sanitized = TimeSanitizer.output(start_time)
    end_time_sanitized = TimeSanitizer.output(end_time)
    opening_local(start_time_sanitized) <= start_time_sanitized &&
      closing_local(start_time_sanitized) >= end_time_sanitized
  end

  # Returns opening time as hh:mm in local time
  def opening(day)
    Time.current.utc.midnight
        .advance(seconds: opening_second(day)).to_s(:time)
  end

  # Returns closing time as hh:mm in local time
  def closing(day)
    Time.current.utc.midnight
        .advance(seconds: closing_second(day)).to_s(:time)
  end

  def opening_local(date)
    dow = date.strftime('%a').downcase
    TimeSanitizer.add_seconds(date, opening_second(dow))
  end

  def public_opening_local(date)
    dow = date.strftime('%a').downcase
    TimeSanitizer.add_seconds(date, public_opening_second(dow))
  end
  
  def closing_local(date)
    dow = date.strftime('%a').downcase
    TimeSanitizer.add_seconds(date, closing_second(dow))
  end

  def public_closing_local(date)
    dow = date.strftime('%a').downcase
    TimeSanitizer.add_seconds(date, public_closing_second(dow))
  end

  def opening_second(day)
    (business_hours.dig(day, :opening) || 0).to_i
  end

  def public_opening_second(day)
    (public_business_hours.dig(day, :opening) || 0).to_i
  end

  def closing_second(day)
    (business_hours.dig(day, :closing) || 86399).to_i
  end

  def public_closing_second(day)
    (public_business_hours.dig(day, :closing) || 86399).to_i
  end

  private

  # @OUTPUT method
  def daily_business_hours(day)
    [{
      start: Time.zone.today.at_beginning_of_day.to_s(:time),
      end: opening(DAYS[day]),
      dow: [day]
    }, {
      start: closing(DAYS[day]),
      end: Time.zone.today.at_end_of_day.to_s(:time),
      dow: [day]
    }]
  end

  def business_hours_pair(hours, dow)
    { opening: tod(hours[:opening][dow]), closing: tod(hours[:closing][dow]) }
  end

  # business hours are excempt from time sanitization including comparison in
  # in_business? due to problems with wrap arounds
  # 1 AM local opening time becomes 22:00 in seconds_since_midnight utc
  # maybe a better way to handle wrap around
  def tod(time)
    Time.zone.parse(time).seconds_since_midnight
  end

  def validate_business_hours
    return if business_hours.blank?

    DAYS.each do |day|
      opening_second = business_hours.dig(day, :opening)
      closing_second = business_hours.dig(day, :closing)
      day_translation = I18n.t("errors.venue.list.#{day.to_s}")

      if opening_second.blank? || opening_second < 0 || opening_second > 86399
        errors.add(:business_hours,
          I18n.t('errors.venue.business_hours.opening', day: day_translation))
      end

      if closing_second.blank? || closing_second < 0 || closing_second > 86399
        errors.add(:business_hours,
          I18n.t('errors.venue.business_hours.closing', day: day_translation))
      end

      if opening_second.present? && closing_second.present? && opening_second >= closing_second
        errors.add(:business_hours,
          I18n.t('errors.venue.business_hours.timing', day: day_translation))
      end
    end
  end
end
