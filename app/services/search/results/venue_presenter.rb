class Search::Results::VenuePresenter < SimpleDelegator
  attr_reader :courts, :lowest_price

  def initialize(venue, search, user, all_courts)
    super(venue)
    @courts = search.available_courts_for(venue).map do |court|
      all_courts << court unless all_courts.include?(court)
      Search::Results::CourtPresenter.new(court, venue, search, user)
    end
    @lowest_price = @courts.map(&:lowest_price).min
  end

end
