json.id court.id
json.court_name court.court_name
json.available_times court.available_times(duration, date) do |time_frame|
  price = court.price_at(time_frame.starts, time_frame.ends, current_user&.discount_for(court, time_frame.starts, time_frame.ends))
  json.starts_at time_frame.starts.in_time_zone
  json.ends_at time_frame.ends.in_time_zone
  json.duration time_frame.duration
  json.price price
  json.stripe_fee court.convenience_fee(price)
end
