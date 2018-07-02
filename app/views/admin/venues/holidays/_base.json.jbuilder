json.(holiday, :id, :created_at, :updated_at)

json.start_time TimeSanitizer.output(holiday.start_time)
json.end_time TimeSanitizer.output(holiday.end_time)

json.courts holiday.courts do |court|
  json.partial! 'admin/venues/courts/base', court: court
end

json.court_ids holiday.court_ids
