class API::UserCountriesController < API::BaseController
  before_action :authenticate_request!
  before_action :set_country

  def update
    if current_user.update(default_country_id: @country.id)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def set_country
    country_id = params[:country_id]
    @country = Country.find_country(country_id)
    head :not_found unless @country
  end

end
