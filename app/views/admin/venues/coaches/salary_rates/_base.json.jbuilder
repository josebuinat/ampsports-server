json.(salary_rate, :id, :coach_id, :venue_id, :sport_name, :rate,
                   :weekdays, :created_at, :updated_at)

json.start_time TimeSanitizer.output(salary_rate.start_time)
json.end_time TimeSanitizer.output(salary_rate.end_time)
