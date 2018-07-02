module ClockTypeTimeFormat
  extend ActiveSupport::Concern

  included do
    before_action :set_clock_type_time_formats

    def set_clock_type_time_formats
      user = current_admin ? current_admin : current_user

      if user
        Time::DATE_FORMATS[:user_clock_time] = Time::DATE_FORMATS[user.time_format]
      elsif country = Country.find_by_id(params[:country_id])
        if country.iso_2 == "US"
          Time::DATE_FORMATS[:user_clock_time] = Time::DATE_FORMATS[:time12]
        end
      end
      Time.set_user_clock_date_time_formats
    end
  end
end
