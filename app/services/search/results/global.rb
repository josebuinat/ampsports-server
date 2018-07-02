class Search::Results::Global < SimpleDelegator
  attr_accessor :venues, :all_courts

  def initialize(search)
    super(search)
    @search = search
  end

  def wrap(user)
    @all_courts = []
    @venues = @search.venues.map do |venue|
      Search::Results::VenuePresenter.new(venue, @search, user, @all_courts)
    end

    self
  end

end
