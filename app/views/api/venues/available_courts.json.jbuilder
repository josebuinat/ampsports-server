json.venue do
  json.partial! 'api/venues/base', venue: @search.venue
  json.opening_local @search.venue.opening_local(@search.date)
  json.closing_local @search.venue.closing_local(@search.date)
end

json.connected_venue do
  if @search.connected_venue.present?
    json.partial! 'api/venues/base', venue: @search.connected_venue
    json.opening_local @search.connected_venue.opening_local(@search.date)
    json.closing_local @search.connected_venue.closing_local(@search.date)
  end
end

json.courts @search.courts do |court|
  json.partial! 'api/search/court_availability', court: court, date: @search.date, duration: court.minimum_duration
end

# note: we render @search.courts as a all_courts, as in case of venue search we
# need to spit out all courts of that venue
json.all_courts(@search.courts) do |court|
  json.partial! 'api/courts/base', court: court
end

json.metadata @search.metadata