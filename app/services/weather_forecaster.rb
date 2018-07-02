require 'httparty'

class WeatherForecaster
  def self.call(venue, dates)
    new(venue, dates).by_dates
  end

  def initialize(venue, dates)
    @venue = venue
    @dates = dates
  end

  def by_dates
    @dates.reduce({}) do |sum, date|
      sum.merge({
        date => for_date(date)
      })
    end
  end

  private

  def for_date(datetime)
    return nil unless has_geo_data?
    time = TimeSanitizer.input(datetime).strftime('%s')

    Rails.cache.fetch("weather_forecast/#{@venue.id}/#{time}", expires_in: 3.days) do
      options = {
        exclude: %w(daily minutely hourly alerts flags).join(','),
      }

      response = HTTParty.get build_url(options, time)
      # put this in cache
      response['currently']
    end
  end

  def secret_key
    Rails.application.secrets.darksky_key
  end

  def build_url(options, time)
    # https://api.darksky.net/forecast/[key]/[latitude],[longitude]
    base_url = "https://api.darksky.net/forecast/#{secret_key}/#{@venue.latitude},#{@venue.longitude},#{time}"
    query_string = options.to_a.map { |hash| "#{hash.first}=#{hash.last}" }.join('&')
    "#{base_url}?#{query_string}"
  end

  def has_geo_data?
    @venue.latitude.present? && @venue.longitude.present?
  end

end