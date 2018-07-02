# Common custom settings for User and Admin
module ClockType
  extend ActiveSupport::Concern

  included do
    enum clock_type: ['12h', '24h']
  end

  # returns Time::DATE_FORMATS symbol format
  def time_format
    return :time12 if new_us_user?

    clock_type == '12h' ? :time12 : :time24
  end

  def new_us_user?
    self.is_a?(User) && created_at == updated_at && venues.first&.country&.US?
  end
end
