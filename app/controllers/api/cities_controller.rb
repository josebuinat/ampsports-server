class API::CitiesController < API::BaseController
  def index
    # initcap: Convert the first letter of each word to upper case and the rest to lower case.
    # LoNDoN, LONDON, london -> London
    venues = Venue.viewable
    if params[:country].present?
      country = Country.find_country(params[:country])
      venues = venues.by_country(country.id)
    end
    @cities = venues.pluck("distinct coalesce(initcap(city), '')").sort
  end
end
