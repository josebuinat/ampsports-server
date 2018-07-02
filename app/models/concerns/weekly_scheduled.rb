# handles weekdays and minute_of_a_day manipulations for Price and Coach::SalaryRate
module WeeklyScheduled extend ActiveSupport::Concern
  WEEKDAYS = [:sunday, :monday, :tuesday,
              :wednesday, :thursday,
              :friday, :saturday].freeze

  included do
    include TimeSpreadable
    time_spreadable_columns('start_minute_of_a_day', 'end_minute_of_a_day')

    validates :start_minute_of_a_day, presence: true
    validates :end_minute_of_a_day, presence: true, numericality: { greater_than: :start_minute_of_a_day }
    validate :presence_of_weekday

    scope :for_weekdays, ->(days) do
      where(WEEKDAYS.map { |day| "#{day.to_s} = true" if days.include?(day) }.compact.join(' OR '))
    end

    def start_time
      return nil unless self.start_minute_of_a_day
      h = self.start_minute_of_a_day / 60
      m = self.start_minute_of_a_day % 60
      TimeSanitizer.output_input("2000-01-01T#{h}:#{m}:00")
    end

    def start_time=(val)
      if val.kind_of?(Time) || val.kind_of?(DateTime)
        self.start_minute_of_a_day = val.minute_of_a_day
      elsif val.kind_of?(String)
        self.start_minute_of_a_day = TimeSanitizer.output_input(val).minute_of_a_day
      end
    end

    def end_time
      return nil unless self.end_minute_of_a_day
      h = self.end_minute_of_a_day / 60
      m = self.end_minute_of_a_day % 60
      TimeSanitizer.output_input("2000-01-01T#{h}:#{m}:00")
    end

    def end_time=(val)
      if val.kind_of?(Time) || val.kind_of?(DateTime)
        self.end_minute_of_a_day = val.minute_of_a_day
      elsif val.kind_of?(String)
        self.end_minute_of_a_day = TimeSanitizer.output_input(val).minute_of_a_day
      end
    end

    def weekdays
      WEEKDAYS.select { |day| self.send(day) }
    end

    def weekdays=(days)
      WEEKDAYS.each do |day|
        self.send("#{day.to_s}=", (days.include?(day) || days.include?(day.to_s)))
      end
    end

    private

    def presence_of_weekday
      unless weekdays.any?
        errors.add :weekdays, 'please select at least one weekday'
      end
    end
  end
end
