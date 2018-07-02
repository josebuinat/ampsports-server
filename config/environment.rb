# Load the Rails application.
require File.expand_path('../application', __FILE__)
require 'icalendar'
# Initialize the Rails application.
Rails.application.initialize!

Time::DATE_FORMATS[:time24] = '%H:%M'
Time::DATE_FORMATS[:time12] = '%I:%M %p'
Time::DATE_FORMATS[:time] = Time::DATE_FORMATS[:time24]
Time::DATE_FORMATS[:date] = '%d/%m/%Y'
Date::DATE_FORMATS[:date] = Time::DATE_FORMATS[:date]
Time::DATE_FORMATS[:time_date] = "#{Time::DATE_FORMATS[:time]} #{Time::DATE_FORMATS[:date]}"
Time::DATE_FORMATS[:date_time] = "#{Time::DATE_FORMATS[:date]} #{Time::DATE_FORMATS[:time]}"

Time::DATE_FORMATS[:user_clock_time] = Time::DATE_FORMATS[:time24]

class Time
  def self.set_user_clock_date_time_formats
    Time::DATE_FORMATS[:user_clock_time_date] = "#{Time::DATE_FORMATS[:user_clock_time]} #{Time::DATE_FORMATS[:date]}"
    Time::DATE_FORMATS[:user_clock_date_time] = "#{Time::DATE_FORMATS[:date]} #{Time::DATE_FORMATS[:user_clock_time]}"
  end

  def self.with_user_clock_type(user, &block)
    initial_clock_time_format = Time::DATE_FORMATS[:user_clock_time]
    initial_date_format = Time::DATE_FORMATS[:date]

    Time::DATE_FORMATS[:date] = user&.locale == 'en' ? '%m/%d/%Y' : '%d/%m/%Y'
    Time::DATE_FORMATS[:user_clock_time] = Time::DATE_FORMATS[user.time_format] if user
    set_user_clock_date_time_formats

    result = yield

    Time::DATE_FORMATS[:user_clock_time] = initial_clock_time_format
    Time::DATE_FORMATS[:date] = initial_date_format
    set_user_clock_date_time_formats

    result
  end
end

Time.set_user_clock_date_time_formats
