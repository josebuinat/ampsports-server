# Main search code; Search::Global and Search::OnVenue are small modifications of these one
class Search::Core
  include Memoization
  attr_reader :sport_name, :date

  def initialize(sport_name:, date:)
    @sport_name = if sport_name.is_a?(String) || sport_name.is_a?(Symbol)
      Court.sport_names[sport_name]
    else
      sport_name
    end
    @date = date || Date.tomorrow
  end

  # returns an array of available courts for that venue
  def available_courts_for(venue)
    memoize(venue) do
      venue_id = venue.respond_to?(:id) ? venue.id : venue
      connected_venue_id = venue.respond_to?(:connected_venue_id) ? venue.connected_venue_id : nil
      courts_scope.select do |court|
        Time.use_zone(venue.timezone) do
          if [venue_id, connected_venue_id].include?(court.venue_id)
            court.any_available_times?(@duration, @date)
          else
            false
          end
        end
      end
    end
  end

  # Returns general scope for venues, transform it to a collection (paginate for main page)
  # Either call .find on it to get the venue (for venue#show page)
  def venues_scope
    @venues_scope ||= Venue.distinct.includes(:courts).searchable.
      # display venues which support desired sport
      where(courts: { sport_name: @sport_name }).
      # those who are willing to wait us
      where('booking_ahead_limit >= ?', (@date.to_datetime - Date.current).to_i).
      # do not show courts without price
      joins(courts: :prices).
      # and preload stuff
      includes(:photos)
  end

  def prepopulated_venues_scope
    @prepopulated_venues_scope ||= Venue.distinct.includes(:photos).prepopulated_or_searchable
  end

  # Returns general scope for courts
  # to not display courts without pricing, for wrong sport etc
  def courts_scope
    @courts_scope ||= Court.active.common.
      # only for sport we are interested in
      where(sport_name: @sport_name).
      # do not include courts without pricing
      joins(:prices).
      # call include stuff we need to include
      includes(:prices, :holidays, :shared_courts, venue: [:photos])

    # If we add includes(:reservation), add this as well (to not join thousands of unnecessary records)
    #   where("reservations.start_time IS NULL OR reservations.start_time::date = ?", @date)
    # But this makes a clause on left outer join, which removes courts without reservation
    # Fancy preload doesn't work either (still fires N+1 queries); so, if anyone knows the solution
    # to preload those records - feel free to add it
  end

  # Override in a descendant if need to pass additional data into view
  def metadata
    {}
  end
end
