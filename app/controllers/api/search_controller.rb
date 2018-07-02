class API::SearchController < API::BaseController
  # main page search, returns all venues fit for this query
  def venues
    search = Search::Global.new(
      date: TimeSanitizer.input(params[:date]),
      duration: params[:duration].to_i,
      sport_name: params[:sport_name],
      time: params[:time],
      location: {
        city_name: params[:city],
        country: params[:country],
        bounding_box: bounding_box,
      },
      sort_by: 'distance',
    ).call
    @search_results = Search::Results::Global.new(search).wrap(current_user)
    SegmentAnalytics.all_venues_search(current_user, tracked_params)
  end

  # returns cities and venues names for the top search
  def filter_by_name
    @search = Search::ByName.new(
      term: params[:name],
      country: params[:country]
    ).call
  end

  private

  def tracked_params
    params.permit(
      :sport_name,
      :city,
      :duration).
      merge(
        search_date: @search_results.date,
        search_time: params[:time]
      )
  end

  def bounding_box
    coordinates = params[:bounding_box] || { }
    # do not pass more than these args, and make sure all values are
    attrs = %i(sw_lat sw_lng ne_lat ne_lng)
    return nil if attrs.any? { |attr| coordinates[attr].blank? }
    coordinates.slice(*attrs).transform_values! { |value| value.to_f }
  end

end
