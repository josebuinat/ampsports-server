json.venues(@venues) do |venue|
  json.partial! 'api/venues/base', venue: venue
  json.supported_sports venue.supported_sports
  json.lowest_price venue.prices.map(&:price).sort.first.to_i
end
