# Represents a sports venue
class Venue < ActiveRecord::Base
  extend ActiveHash::Associations::ActiveRecordExtensions
  include BusinessHours
  include VenueTimeFrames
  include VenueStatus
  include CustomColors
  include Memoization
  include Settings
  has_settings :calendar, {
    show_coach: false,
    show_coach_first: false,
    show_time: true,
    show_tooltip: false,
    show_should_submit_email_prompt: true,
  }

  MAX_COURT_INDEX = 999

  store :business_hours, coder: Hash
  store :court_counts, coder: Hash

  belongs_to_active_hash :country

  belongs_to :company
  has_many :favourite_venues, dependent: :destroy
  has_many :favourited_by, through: :favourite_venues, source: :user
  has_many :courts, dependent: :destroy, inverse_of: :venue
  has_many :venue_user_connectors
  has_many :reservations, through: :courts
  has_many :holidays, -> { distinct }, through: :courts
  has_many :prices, through: :courts
  has_many :photos, dependent: :destroy
  has_one :primary_photo, class_name: 'Photo'
  has_many :users, through: :venue_user_connectors
  has_many :memberships, dependent: :destroy
  has_many :discounts, dependent: :destroy
  has_many :email_lists
  has_many :custom_mails
  has_many :game_passes, dependent: :destroy
  has_one  :connected_venue, class_name: 'Venue', foreign_key: :connected_venue_id
  has_many :reviews
  has_many :groups, dependent: :destroy
  has_many :group_classifications, dependent: :destroy
  has_many :coach_salary_rates, class_name: 'Coach::SalaryRate'
  has_many :coach_price_rates, class_name: 'Coach::PriceRate'
  has_many :coaches, through: :coach_price_rates

  enum status: [:hidden, :searchable, :prepopulated]

  before_create :set_counts
  before_create :set_country

  accepts_nested_attributes_for :photos, allow_destroy: true

  WEEKDAYS = [:monday, :tuesday,
              :wednesday, :thursday,
              :friday, :saturday,
              :sunday].freeze

  accepts_nested_attributes_for :courts, :prices, :reservations

  geocoded_by :venue_address
  after_validation :geocode_and_set_timezone, if: :venue_address_changed?

  validates :venue_name, presence: true
  validates :description, presence: true
  # validates :parking_info, presence: true
  # validates :transit_info, presence: true
  # validates :website, presence: true
  # validates :phone_number, presence: true
  validates :booking_ahead_limit, presence: true
  validate :validate_searchable, if: 'status_changed? && searchable?'

  scope :sport, ->(sport) {
    where(id: Court.for_sport(sport).select(:venue_id).distinct )
  }
  scope :by_city, ->(city_name) { where('city ilike ?', city_name) }
  scope :by_country, -> (country_id) { where(country_id: country_id) }
  scope :viewable, ->{ where.not(status: Venue.statuses[:hidden]) }
  scope :prepopulated_or_searchable, -> { where(status: [ statuses[:searchable], statuses[:prepopulated] ]) }

  class << self

    def tennis
      Venue.searchable.select {|v| v.supported_sports.include?("tennis")}
    end

    def padel
      Venue.searchable.select {|v| v.supported_sports.include?("padel")}
    end

    def all_sport_names
      Court.joins(:venue).
            where(venues: { status: statuses[:searchable] }).
            pluck('distinct sport_name').
            map { |x| Court.sport_names.key(x) }
    end

    def reservation_data_for_collection(venues, time, duration, sport_name)
      venues.map do |venue|
        reservations = venue.
          get_reservation_data_around(time, duration, sport_name)
        {
          id: venue.id,
          photos: venue.photos,
          reservations: reservations,
          venue_lowest: venue_lowest(reservations),
          name: venue.venue_name
        }
      end
    end

    def venue_lowest(reservations)
      reservations.map { |r| r.second['lowest_price'] }.min
    end
  end

  private_class_method :venue_lowest

  def supported_sports
    # TODO(aytigra): This block doesn't actually work, needs check for dependency and cleanup
    self.courts.map(&:sport_name).uniq.compact do |sport|
      [Court.human_attribute_name("sport_name.#{sport}"), sport]
    end
  end

  def supported_sports_with_private
    supported_sports + (courts.any?(&:private?) ? ['private'] : [])
  end

  def supported_sports_options
    supported_sports.map do |sport|
      { value: sport, label: Court.human_attribute_name("sport_name.#{sport}") }
    end
  end

  def supported_surfaces
    self.courts.map(&:surface).uniq.compact
  end

  def courts_by_surface_json(surface)
    courts.select { |court| !court.active? && court.surface == surface}
      .map do |court|
        {
          start: Time.zone.today.at_beginning_of_day,
          end: (Time.zone.today + 10.years).at_end_of_day,
          resourceId: court.id
        }
      end
  end

  def image_urls
    images = photos.map(&:image)
    images.map(&:url)
  end

  def venue_address_changed?
    city_changed? || zip_changed? || street_changed?
  end

  def venue_address
    "#{street}, #{city} #{zip}"
  end

  def booking_date_limit
    Date.current + booking_ahead_limit.days
  end

  def active_courts_json
    courts.reject(&:active?)
          .map do |court|
            {
              start: Time.zone.today.at_beginning_of_day,
              end: (Time.zone.today + 10.years).at_end_of_day,
              resourceId: court.id
            }
          end
  end

  # check that date can be booked while respecting booking ahead limit
  def bookable?(date)
    date < booking_date_limit
  end

  def set_primary_photo(photo_id = nil)
    new_primary = photo_id || photos.first&.id
    update_attributes(primary_photo_id: new_primary)
  end

  def set_counts
    self.court_counts = {
      indoor: {},
      outdoor: {}
    }
  end

  # this callback makes it impossible to create venue with country different form company's
  def set_country
    self.country = self.company.country
  end

  def geocode_and_set_timezone
    geocode
    VenueTimezoneUpdater.new(self).set_timezone if persisted? || timezone.blank?
  end

  def try_photo_url(style = nil)
    photos.first.try(:image).try(:url, style)
  end

  def add_customer(user, track_with_actor: nil)
    if user.is_a?(User) && !connected_user?(user)
      VenueUserConnector.create(user: user, venue: self)

      if track_with_actor.is_a?(User)
        SegmentAnalytics.user_added_to_venue_via_online(user, self)
      elsif track_with_actor.is_a?(Admin)
        SegmentAnalytics.user_added_to_venue_via_admin(user, self, track_with_actor)
      end
    end
  end

  def connected_user?(user)
    users.include?(user)
  end

  # returns indexes available for court(including current index for existing court)
  def available_court_indexes(court, number_of_consecutive = 1)
    return [] if court.blank? ||
                 !court.is_a?(Court) ||
                 (court.sport_name.blank? && court.custom_name.blank?)

    # index either by custom name or by type and sport
    if court.custom_name.present?
      search_params = { custom_name: court.custom_name }
    else
      search_params = {
        indoor: court.indoor.present?,
        sport_name: Court.sport_names[court.sport_name],
        custom_name: nil }
    end

    taken_indexes = courts.where(search_params).where.not(id: court.id).pluck(:index)

    available_indexes = (1..MAX_COURT_INDEX).to_a - taken_indexes

    MathExtras.start_with_consecutive(available_indexes, number_of_consecutive)
  end

  def has_shared_courts?
    courts.includes(:shared_courts).any? do |court|
      court.shared_courts.length > 0
    end
  end

  # returns map with court_id as key and array of shared courts as values
  def shared_courts_map
    shared_courts_map = {}
    courts.each do |court|
      shared_courts_map[court.id] = court.shared_courts
    end
    shared_courts_map
  end

  # returns actual reservations along with their copies for shared courts
  # to indicate bookings in shared courts
  def reservations_shared_courts_json(start_date, end_date)
    reservations_json = reservations_between_dates(start_date, end_date).
                          includes(:classification, :coaches, :venue).
                          map { |r| r.as_json_for_calendar(id) }

    if has_shared_courts?
      reservations_supported_shared_courts = reservations_json.select do |x|
        # show shared courts for ones which are not on resell
        # and for which are and don't allow to book chunk
        !x[:reselling] || !allow_overlapping_resell
      end
      shared_courts_hash = shared_courts_map
      shared_reservations_json = reservations_supported_shared_courts.map do |reservation|
        shared_courts_hash[reservation[:resourceId]].map do |shared_court|
          court = Court.find(reservation[:resourceId])
          reservation.dup.tap do |reservation_copy|
            reservation_copy[:title] += " - #{court.court_name} (#{court.sport_name})"
            reservation_copy[:resourceId] = shared_court.id
            reservation_copy[:shared] = true
          end
        end
      end.flatten
    end
    reservations_json + shared_reservations_json.to_a
  end

  def reservations_between_dates(start_date, end_date)
    reservations.
      includes(:user, :membership, court: :venue).
      where('start_time >= ? and start_time < ?', start_date, end_date)
  end

  def has_available_slot?(time_frame, sport_name = nil)
    memoize(time_frame, sport_name) do
      c = if sport_name.nil?
          courts
        else
          sn = sport_name.is_a?(Integer) ? Court.sport_names.key(sport_name) : sport_name
          courts.select { |x| x.sport_name == sn }
        end
      c.any? { |court| court.has_available_slot?(time_frame) }
    end
  end

  # two-ways binding
  def connect_venue(venue)
    return unless venue.is_a?(Venue) && connected_venue.blank?

    transaction do
      self.update_attribute(:connected_venue_id, venue.id)
      venue.update_attribute(:connected_venue_id, self.id)
      reload
    end
  end

  def disconnect_venue
    transaction do
      self.update_attribute(:connected_venue_id, nil)
      connected_venue.update_attribute(:connected_venue_id, nil)
      reload
    end
  end

  def total_revenue(start_date, end_date)
    reservations.where('reservations.start_time::date between ? and ?', start_date, end_date).sum(:amount_paid) || 0
  end

  def average_rating
    return 0 if reviews.blank?
    average = reviews.average(:rating)
    MathExtras.round_to_half_decimal(average)
  end

  def public_business_hours
    return @public_business_hours if @public_business_hours
    return business_hours if prepopulated?

    prices = courts.flat_map(&:prices)
    return business_hours if prices.blank?

    days = %w(monday tuesday wednesday thursday friday saturday sunday)
    @public_business_hours = days.reduce({}) do |sum, day|
      # check price not nil for this day
      hours = prices.select { |price| price[day] }.
        flat_map { |price| [price.start_minute_of_a_day, price.end_minute_of_a_day] }.
        minmax

      short_day_name = day[0..2]
      sum.merge(short_day_name => if hours.all?
                                    {
                                      # convert minutes into seconds
                                      opening: hours[0] * 60,
                                      closing: hours[1] * 60
                                    }
                                  else
                                    business_hours[short_day_name]
                                  end)
    end.with_indifferent_access
  end

  # find timeslots for required sport and datetimes range
  # which are fully booked(all courts of this sport has reservations)
  # free_for_coach_id indicates that if all courts are booked for given timeframe BUT one of reservations
  # is assigned to this coach, then it is marked as free; it is needed for calendar, otherwise reservation
  # on calendar will interesect with unavailable zone and hence be marked as non-editable
  def unavailable_slots(sport, start_time, end_time, free_for_coach_id = nil)
    free_for_coach_id = free_for_coach_id.to_i
    sport_courts = if sport.present?
      courts.for_sport(sport)
    elsif free_for_coach_id > 0
      courts.for_sport(Coach.find(free_for_coach_id).sports)
    else
      courts
    end
    sport_court_ids = sport_courts.pluck(:id).sort

    taken_timeslots = reservations.where(court_id: sport_court_ids).
                                   overlapping(start_time, end_time).
                                   select(:start_time, :end_time, :court_id, :coach_id)

    unavailable_slots = []

    # bruteforce here, check each of 15 minutes part of datetimes range
    while end_time > start_time do
      ends = start_time + 15.minutes
      taken_courts = taken_timeslots.map do |timeslot|
        reservation_belongs_to_coach = free_for_coach_id > 0 && timeslot.coach_id == free_for_coach_id
        if timeslot.overlapping?(start_time, ends) && !reservation_belongs_to_coach
          timeslot.court_id
        end
      end.compact.uniq.sort

      unavailable_slots << { start: start_time, end: ends } if taken_courts == sport_court_ids

      start_time += 15.minutes
    end

    # combine slots
    unavailable_slots.
      chunk_while { |prv, nxt| prv[:end] == nxt[:start] }.
        flat_map { |chunk| { start: chunk.first[:start], end: chunk.last[:end] } }
  end
end
