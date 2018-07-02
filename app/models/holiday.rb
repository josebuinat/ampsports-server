class Holiday < ActiveRecord::Base
  include Sortable
  # Failing for some reason, try to understand why
  virtual_sorting_columns({
    courts_count: {
      select: 'count(courts.id) as courts_count',
      joins: <<~SQL,
        left outer join courts_holidays on courts_holidays.holiday_id = holidays.id
        left outer join courts on courts_holidays.court_id = courts.id
      SQL
      group: 'holidays.id',
      order: :courts_count
    }
  })

  has_and_belongs_to_many :courts, inverse_of: :holidays
  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :dates_valid, if: 'start_time && end_time'
  validate :courts_presence


  def dates_valid
    if end_time < start_time
      errors.add(:end_time, 'incorrect date range selected')
    end
  end

  # @OUTPUT
  def as_json(options = {})
    super(options).merge!(
      {
        'start' => (TimeSanitizer.output(start_time) unless start_time.nil?),
        'end' => (TimeSanitizer.output(end_time) unless end_time.nil?),
        'resourceIds' => courts.pluck(:id)
      }
    )
  end

  def for_whole_venue?
    venue = courts.first.venue
    courts.pluck(:id).sort == venue.courts.active.pluck(:id).sort
  end

  def covers?(start_time, end_time)
    holiday = (self.start_time + 1.second..self.end_time - 1.second)
    reservation = (start_time + 1.second..end_time - 1.second)
    reservation.overlaps?(holiday)
  end

  def conflicting_reservations
    @conflicting_reservations ||= Reservation.where(
      'start_time BETWEEN :start_time AND :end_time OR end_time BETWEEN :start_time AND :end_time',
      start_time: start_time, end_time: end_time
    ).where(court_id: court_ids).includes(:court)
  end

  private

  def courts_presence
    if courts.blank?
      errors.add :court_ids, :blank
    end
  end
end
