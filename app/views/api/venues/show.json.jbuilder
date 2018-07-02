json.partial! 'api/venues/base', venue: @venue
json.venue_id @venue.id
json.lowprice @venue.courts.active.flat_map{ |c| c.prices.map(&:price)}.sort.first
json.highprice @venue.courts.active.flat_map{ |c| c.prices.map(&:price)}.sort.last
json.transit_info @venue.transit_info
json.parking_info @venue.parking_info
json.description @venue.description
json.business_hours @venue.public_business_hours
json.longitude @venue.longitude
json.latitude @venue.latitude
json.supported_sports @venue.supported_sports
json.booking_ahead_limit @venue.booking_ahead_limit
json.thumbnails @venue.photos.limit(3) do |photo|
  json.image_url photo.image.url(:thumb)
end
json.images @venue.photos do |photo|
  json.image_url photo.image.url(:medium)
end
