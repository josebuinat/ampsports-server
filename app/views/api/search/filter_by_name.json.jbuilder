json.venues @search.venues do |venue|
  json.partial! 'api/venues/base', venue: venue
end
