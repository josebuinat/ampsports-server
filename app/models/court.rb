# represents one court in a sports venue
class Court < ActiveRecord::Base
  include SportNames
  include Memoization
  include Sortable
  virtual_sorting_columns({
    court_name: {
      order: ->(direction) { "indoor #{direction}, index #{direction}" }
    }
  })
  belongs_to :venue, inverse_of: :courts
  has_many :dividers, dependent: :destroy
  has_many :prices, through: :dividers
  has_many :reservations, dependent: :destroy
  has_and_belongs_to_many :holidays, inverse_of: :courts
  has_many :court_connectors, dependent: :destroy
  has_many :shared_courts, through: :court_connectors
  delegate :country, to: :venue

  validates :sport_name, presence: true
  validates :duration_policy, presence: true
  validates :start_time_policy, presence: true
  validates :venue, presence: true
  validates :index, presence: true

  before_save :court_index, if: 'name_changed?'

  before_save :set_false
  # quick fix for "null value in column "active" violates not-null constraint"
  def set_false
    [:active, :private].each do |att|
      self[att] = false if self[att].blank?
    end
  end

  enum duration_policy: { any_duration: -1,
                          half_hour: 30,
                          one_hour: 60,
                          two_hour: 120 }
  enum start_time_policy: [:any_start_time, :hour_mark, :half_hour_mark, :quarter_hour_mark]
  enum surface: [:other, :hard_court, :red_clay, :green_clay, :artificial_clay, :grass,
                 :artificial_grass, :concrete, :asphalt, :carpet, :turf]

  scope :active, -> { where(active: true) }
  scope :common, -> { where private: false }
  scope :custom, -> { where.not custom_sport_name: nil }
  # naive search implementation
  scope :search, ->(term) do
    r = if term.downcase.start_with?('i')
      where(indoor: true)
    elsif term.downcase.start_with?('o')
      where(indoor: false)
    else
      where(nil)
    end

    index = term.split(' ').map(&:to_i).select(&:positive?).first
    r = r.where(index: index) if index
    r
  end

  def to_s
    court_name
  end

  def payment_skippable
    return false if country.US?

    self[:payment_skippable]
  end
  # override default method to follow conditioned version
  alias payment_skippable? payment_skippable

  def price_at(start_time, end_time, discount = nil)
    start_time = TimeSanitizer.output(start_time)
    end_time = TimeSanitizer.output(end_time)
    hours = TimeSanitizer.duration(start_time, end_time).to_f / (60*60)

    final_price = prices.map { |price| price.apply(start_time, end_time) }.sum

    discount.is_a?(Discount) ? discount.apply(final_price, hours) : final_price
  end

  # should have price rules covering whole timeslot
  def has_price?(start_time, end_time)
    start_minute = TimeSanitizer.output(start_time).minute_of_a_day
    end_minute = TimeSanitizer.output(end_time).minute_of_a_day
    day = TimeSanitizer.output(start_time).strftime('%A').to_s.downcase.to_sym

    MathExtras.subtract_ranges(
      [[start_minute, end_minute]],
      prices_timeranges(start_minute, end_minute, day)
    ).length == 0
  end

  def prices_timeranges(start_minute, end_minute, day)
    prices.map do |p|
      if p.applies_to?(start_minute, end_minute, day)
        [p.start_minute_of_a_day, p.end_minute_of_a_day]
      end
    end.compact
  end

  def calculate_stripe_fee(amount)
    if country.US?
      amount * 0.029 + 0.3
    elsif country.FI?
      amount * 0.014 + 0.25
    else
      amount
    end
  end

  def convenience_fee(amount)
    fee = if country.US?
            amount_with_fee = (amount + calculate_stripe_fee(amount)) * 1.005
            amount_with_fee - amount
          else
            0
          end
    (fee * 100).ceil.to_f / 100
  end

  def reservations_during(start_time, end_time)
    started = reservations.where(start_time: (start_time - 1.minute)..(end_time + 1.minute))
    ended = reservations.where(end_time: start_time..end_time)
    between = reservations.where('start_time <= ?', start_time)
                          .where('end_time >= ?', end_time)
    started + ended + between
  end

  def working?(start_time, end_time)
    return false unless venue.in_business?(start_time, end_time)
    # no holiday is going at this time frame
    holidays.none? { |holiday| holiday.covers?(start_time, end_time) }
  end

  def bookable?(start_time, end_time, price)
    Reservation.new(start_time: start_time,
                    end_time:   end_time,
                    court:      self,
                    price:      price,
                    user:       User.new,
                    booking_type: :online).valid?
  end

  def can_start_at?(time)
    any_start_time? ||
      (half_hour_mark? && time.min == 30) ||
      (hour_mark? && time.min == 0) ||
      (quarter_hour_mark? && (time.min == 15 || time.min == 45))
  end

  def court_name
    type = indoor ? 'indoor' : 'outdoor'
    name = Court.human_attribute_name("court_name.#{type}")

    name = custom_name if custom_name.present?

    "#{name} #{index}"
  end

  def sport
    if private?
      Court.human_attribute_name("sport_name.private")
    else
      Court.human_attribute_name("sport_name.#{sport_name}")
    end
  end

  def court_name_with_sport
    "#{court_name} (#{sport})"
  end

  def available_times(duration, date, include_past = false)
    get_available_times(duration, date, include_past)
  end

  def any_available_times?(duration, date)
    !get_available_times(duration, date).empty?
  end

  def has_available_slot?(time_frame)
    available_on?(time_frame)
  end

  def available_on?(time_frame)
    # start time policy
    can_start_at?(time_frame.starts) &&
      # # not on offday
      working?(time_frame.starts, time_frame.ends) &&
      # # has price
      has_price?(time_frame.starts, time_frame.ends) &&
      # # not reserved
      !reserved_on?(time_frame) &&
      # # not reserved for any of its shared_courts
      !shared_courts_reserved_on?(time_frame)
  end

  def reserved_on?(time_frame)
    today_reservations = memoize(time_frame.date) do
      # if this thing was preloaded by "includes" or something, then we assume
      # it's already holding only todays reservations
      if reservations.loaded?
        reservations
      else
        reservations.where('start_time::date = ?', time_frame.date)
      end
    end
    today_reservations.any? { |r| r.conflicting?(time_frame.starts, time_frame.ends) }
  end

  def shared_courts_reserved_on?(time_frame)
    shared_courts.any?{ |shared_court| shared_court.reserved_on?(time_frame) }
  end

  def minimum_duration
    return 15 if any_duration? && squash?
    return 30 if any_duration?
    self.class.duration_policies[duration_policy]
  end

  # important for :common scope
  def custom_name=(string)
    string = nil if string.blank?
    super
  end

  def self.supported_sports
    sport_names.keys.map do |sport|
      [Court.human_attribute_name("sport_name.#{sport}"), sport]
    end
  end

  def self.all_surfaces
    surfaces.keys.map do |surface|
      [Court.human_attribute_name("surface.#{surface}"), surface]
    end
  end

  def as_json(options)
    court = super(options)
    court[:court_name] = court_name
    court[:sport] = sport
    court
  end

  def playable_for_sport?(sport_name)
    (self.sport_name == sport_name && !private?) || (private? && sport_name == 'private')
  end

  private

  def get_weekday(date)
    date.strftime('%A').to_s.downcase.to_sym if date
  end

  def court_index
    available_indexes = venue.available_court_indexes(self)

    self.index = available_indexes.first unless available_indexes.include?(index)
  end

  def name_changed?
    sport_name_changed? ||
      custom_name_changed? ||
      indoor_changed? ||
      !persisted?
  end

  def get_available_times(duration, date, include_past = false)
    step = squash? ? 15 : 30
    cache_key = "#{id}_#{duration}_#{date}_#{include_past}"
    Rails.cache.fetch(cache_key, expires_in: 5) do
      venue.time_frames(duration, date, include_past, step).select do |time_frame|
        available_on?(time_frame)
      end
    end
  end
end
