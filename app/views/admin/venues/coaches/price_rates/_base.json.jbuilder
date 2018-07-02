json.(price_rate, :id, :coach_id, :venue_id, :sport_name, :rate,
                   :created_at, :updated_at)

json.start_time TimeSanitizer.output(price_rate.start_time)
json.end_time TimeSanitizer.output(price_rate.end_time)
