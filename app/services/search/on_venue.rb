# Used to search on venue page
class Search::OnVenue < Search::Core
  def initialize(sport_name: 'tennis', date: Date.tomorrow, venue:)
    super(sport_name: sport_name, date: date)
    # we want to reload venue from the venue_scope to ensure it's active and all that jazz;
    # therefore, force to store ID here and load it later
    @venue_id = venue.is_a?(Venue) ? venue.id : venue
  end

  def call
    @venue = venues_scope.searchable.find(@venue_id)
    self
  end

  def courts_scope
    @courts_scope ||= super.where(venue_id: [@venue.id, @venue.connected_venue_id])
  end

  def venue
    @venue
  end

  def connected_venue
    @venue.connected_venue
  end

  def courts
    @courts ||= courts_scope
  end
end
