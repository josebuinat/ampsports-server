json.response @search_results.venues do |venue|
  json.venue do
    json.partial! 'api/venues/base', venue: venue
    json.average_rating venue.average_rating
    json.lowest_price venue.lowest_price
  end
  json.courts venue.courts do |court|
    json.partial! 'court_precalc_availability', court: court
  end
end

json.all_courts @search_results.all_courts do |court|
  json.partial! 'api/courts/base', court: court
end

json.metadata @search_results.metadata

# do not duplicate venues we found in an original search
to_shown_as_prepopulated = @search_results.prepopulated_venues - @search_results.venues.map(&:__getobj__)
json.prepopulated to_shown_as_prepopulated do |venue|
  json.partial! 'api/venues/base', venue: venue
end

# render error here, with HTTP status of 200;
# it's 200 because request is perfectly fine, just found nothing
if @search_results.error.present?
  json.error do
    json.error @search_results.error.to_s
    json.message I18n.t("api.search.#{@search_results.error}")
  end
end
