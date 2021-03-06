json.price do
  json.id @price.id
  json.start_time @price.start_time.to_s(:time)
  json.end_time @price.end_time.to_s(:time)
  json.value @price.price
  json.courts @price.courts, :id, :court_name, :sport
  json.days @price.dows
  json.delete_url venue_price_path(@venue, @price)
  json.update_url venue_price_path(@venue, @price)
end
