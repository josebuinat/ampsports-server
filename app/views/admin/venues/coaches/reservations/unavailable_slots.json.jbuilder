json.array! @unavailable_slots do |unavailable_slot|
  json.start TimeSanitizer.output(unavailable_slot[:start])
  json.end TimeSanitizer.output(unavailable_slot[:end])
end