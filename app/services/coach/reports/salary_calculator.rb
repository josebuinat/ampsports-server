class Coach::Reports::SalaryCalculator
  def initialize(coach, venue, start_date:, end_date:, sport:)
    @coach = coach
    @venue = venue
    @start_date = TimeSanitizer.input(start_date)
    @end_date = TimeSanitizer.input(end_date)
    @sport = Court.sport_names[sport]
  end

  def reservations
    from = @start_date.beginning_of_day
    to = @end_date.end_of_day

    @reservations ||= @venue.reservations.
                              joins(:court).
                              for_coach(@coach).
                              between(from, to).
                              includes(:coach_connections).
                              where(courts: { sport_name: @sport })
  end

  def courts
    @courts ||= @venue.courts.where(id: reservations.map(&:court_id).uniq)
  end
end
