json.array! @unavailable_times do |unavailable_time|
  json.start TimeSanitizer.output(unavailable_time.first)
  json.end TimeSanitizer.output(unavailable_time.last)
end