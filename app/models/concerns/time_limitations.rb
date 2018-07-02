# time limitations parsing and checks for GamePass and Discount
# related fields: start_date(date), end_date(date), time_limitations(text)
module TimeLimitations
  extend ActiveSupport::Concern

  DAYS = %w(sun mon tue wed thu fri sat).freeze

  included do
    # { limits: [{ from: 420, to: 810, weekdays: ['mon', 'wed'] }, ...] }
    serialize :time_limitations

    scope :available_for_date, ->(start_date, end_date) do
      t = arel_table
      dates_scope = t[:start_date].lteq(start_date)
                        .or(t[:start_date].eq(nil))
                      .and(t[:end_date].gteq(end_date)
                        .or(t[:end_date].eq(nil)))

      where(dates_scope)
    end

    def usable_at?(start_time, end_time)
      return true unless limits.any?
      weekday = start_time.strftime('%a').downcase

      limits.any? do |limit|
        limit[:from] <= start_time.minute_of_a_day &&
          limit[:to] >= end_time.minute_of_a_day &&
          (limit[:weekdays].blank? || limit[:weekdays].to_a.include?(weekday))
      end
    end

    # return [{ from: '07:00', to: '13:30', weekdays: ['mon', 'wed'] }, ...]
    def time_limitations
      limits.map do |limit|
        from, to = [:from, :to].map do |key|
          TimeSanitizer.add_minutes(Date.current.beginning_of_year, limit[key]).to_s(:time)
        end
        { from: from, to: to, weekdays: limit[:weekdays].to_a }
      end
    end

    # parse [{ from: '07:00', to: '13:30', weekdays: ['mon', 'wed'] }, ...]
    def time_limitations=(raw_limits)
      parsed_limits = raw_limits.to_a.map do |limit|
        limit = limit.to_h.with_indifferent_access
        next unless limit[:from].present? && limit[:to].present?
        # parse times to minute of day format
        from, to = [:from, :to].map do |key|
          hours, minutes = limit[key].split(':').map{ |str| str.to_i }
          hours * 60 + minutes
        end

        weekdays = limit[:weekdays].to_a.map(&:to_s).map(&:strip) & DAYS

        {from: from, to: to, weekdays: weekdays}
      end

      assign_limits parsed_limits.compact.uniq
    end

    def start_date_to_s
      start_date.present? ? start_date.to_s(:date) : ''
    end

    def end_date_to_s
      end_date.present? ? end_date.to_s(:date) : ''
    end

    def dates_limit
      unlimited = I18n.t('unlimited')

      if start_date && end_date
        "#{start_date_to_s} - #{end_date_to_s}"
      elsif start_date
        "#{start_date_to_s} - #{unlimited}"
      elsif end_date
        "#{unlimited} - #{end_date_to_s}"
      else
        unlimited
      end
    end

    def time_limitations_to_s
      return I18n.t('unlimited') if time_limitations.empty?
      limits.map do |limit|
        # for pre-made string we want time in user format
        from, to = [:from, :to].map do |key|
          TimeSanitizer.add_minutes(Date.current.beginning_of_year, limit[key]).to_s(:user_clock_time)
        end
        weekdays = limit[:weekdays].to_a.map { |wday| I18n.t("weekdays_short.#{wday}") }
        weekdays = weekdays.any? ? "(#{weekdays.join(', ')})" : ''

        "#{from}-#{to}#{weekdays}"
      end.join(', ')
    end

    private

    def limits
       # for compatibility with differently stored data through migration
      return self[:time_limitations] if self[:time_limitations].is_a?(Array)

      self[:time_limitations] ||= {}
      self[:time_limitations][:limits].to_a
    end

    def assign_limits(limits)
      self[:time_limitations] ||= {}
      self[:time_limitations][:limits] = limits
    end
  end
end
