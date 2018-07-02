# slightly different type of search, where all you input is just a venue name
class Search::ByName
  attr_reader :venues, :cities

  def initialize(term:, country: )
    @term = term
    @country = country
  end

  def call
    country = Country.find_country(@country)
    @venues = Venue.viewable.where('venue_name ilike :term or city ilike :term', term: "%#{@term}%")
    @venues = @venues.includes(:company, :photos).
                      by_country(country.id).sort_by(&:venue_name) if country
    self
  end

end
