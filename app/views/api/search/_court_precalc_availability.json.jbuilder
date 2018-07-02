json.id court.id
json.court_name court.court_name
json.available_times court.available_times do |time_frame|
  json.payment_skippable court.payment_skippable?
  json.starts_at time_frame.starts
  json.ends_at time_frame.ends
  json.duration time_frame.duration
  json.price time_frame.price
  json.stripe_fee court.convenience_fee(time_frame.price)
end
