# Used on main page. Call `call`, then use `.venues` and `available_courts_for(venue)`
class Search::Global < Search::Core
  SORT_BY_OPTIONS = %w(distance price availability).freeze

  attr_reader :duration, :page

  def initialize(sport_name: 'tennis', date: Date.tomorrow, time: nil,
                 duration: 60, page: 1, location: nil, sort_by: nil, per_page: nil)
    super(sport_name: sport_name, date: date)
    if sort_by && !SORT_BY_OPTIONS.include?(sort_by.to_s)
      raise ArgumentError.new("Wrong sort_by, received `#{sort_by}`, expected on of: #{SORT_BY_OPTIONS.join(', ')}")
    end
    @duration = duration
    @page = page
    @per_page = per_page
    @location = (location || {}).with_indifferent_access
    @sort_by = sort_by.to_s
    @time = time.to_i
  end

  def venues_scope_with_duration
    venues_scope.
      # display courts which satisfy our wannable duration
      where(courts: { duration_policy: duration_to_duration_policy(@duration) })
  end

  def call
    @all_venues = venues_scope_with_duration.
      # now it's "safe" to actually load them and use them as an objects (we will render them in JSON later)
      paginate(page: @page, per_page: @per_page)

    # ensure that connected venues are included into page result(for cross reference with added courts)
    @connected_venues = venues_scope_with_duration.where(id: @all_venues.map(&:connected_venue_id))
    @all_venues = (@all_venues + @connected_venues).uniq

    self
  end

  def venues_scope
    return @venues_scope if @venues_scope
    super
    @venues_scope = filter_by_location(@venues_scope)

    # SQL sorting, must return AR relation
    if sort_by_price?
      @venues_scope = @venues_scope.
        # in `super` already joined :prices (via `includes`), so all we have to do is
        # to select the minimum price
        select('venues.*, min(prices.price) as minimum_price').
        # select minimum price per venue - that's why group by venues.id
        group('venues.id').order('minimum_price asc')
      # as further improvement we can account the time user looks for and sort based on that
      # (not the lowest price throughout a day)
    end

    # Technically, we want to sort by availability here as well;
    # Unfortunately, it turned out too complex and had too many unclear stuff (not only
    # reservation to honor, but also weekends, closing hours etc)
    @venues_scope
  end

  def courts_scope
    @courts_scope ||= super.
      # narrow to courts on the venues we are interested in
      where(venue_id: @all_venues.select(&:id)).
      # do not fetch courts with wrong duration
      where(duration_policy: duration_to_duration_policy(@duration))
  end

  def venues
    return @venues if @venues
    @venues = @all_venues.reject { |v| available_courts_for(v).empty? }
    @venues = sort_and_partition(@venues)
  end

  def prepopulated_venues
    return @prepopulated_venues if @prepopulated_venues
    @prepopulated_venues = filter_by_location(prepopulated_venues_scope)
    @prepopulated_venues = sort_and_partition(@prepopulated_venues)
  end

  # returns the reason what no venues returned
  def error
    # no error, we have venues
    return nil if venues.size > 0
    # if we had venues before removing booked once - it's all booked
    return :all_booked if @all_venues.size > 0
    # otherwise just nothing found based on that criteria
    :nothing_found
  end

  def metadata
    { duration: @duration }
  end

  # returns all used courts in current search
  def all_courts
    @all_courts ||= venues.map { |v| available_courts_for(v) }.flatten.uniq
  end

  SORT_BY_OPTIONS.each do |sort_option|
    define_method "sort_by_#{sort_option}?" do
      @sort_by == sort_option
    end
  end

  private

  def filter_by_location(venues)
    if location_bounding_box.present?
      argument_list = %i(sw_lat sw_lng ne_lat ne_lng).map { |x| location_bounding_box[x] }
      venues = venues.within_bounding_box(argument_list)
    end

    if location_city.present? && location_radius.present?
      # ordering by distance can be done only if location is specified
      order_column = sort_by_distance? && 'distance'
      city = location_city.downcase == 'ambler' ? 'Ambler, PA' : location_city
      # searchable is 1, prepopulated is 2
      venues = venues.order('venues.status ASC')
      venues = venues.near("City of #{city}", location_radius, order: order_column)
    end

    if location_country.present?
      country = Country.find_country(location_country)
      venues = venues.by_country(country.id)
    end

    venues
  end

  def sort_and_partition(venues)
    # Plain ruby sorting, can return an array
    if sort_by_availability? && @time > 0
      minute = @time % 100
      hour = @time / 100
      starts = @date.to_datetime.in_time_zone.change(hour: hour, min: minute)
      ends = starts.advance(minutes: @duration)
      time_frame = TimeFrame.new(starts, ends)

      venues = venues.partition do |venue|
        venue.has_available_slot?(time_frame, @sport_name)
      end
      venues.flatten!
    end

    venues
  end

  def location_city
    @location_city ||= @location[:city_name]
  end

  def location_country
    @location_country ||= @location[:country]
  end

  def location_bounding_box
    @location_bounding_box ||= @location[:bounding_box]
  end

  def location_radius
    # 60 kilometers
    60
  end

  # duration is an integer minutes value
  # search all courts with a minimum duration policy lesser than requested
  def duration_to_duration_policy(duration)
    Court.duration_policies.values.reject{ |dp| dp > (duration || 60).to_i.abs }
  end
end
