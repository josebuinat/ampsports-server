json.courts @courts do |court|
  json.court_id court.id
  json.sport court.sport
  json.name court.court_name
end