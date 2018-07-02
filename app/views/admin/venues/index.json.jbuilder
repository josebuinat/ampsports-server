json.venues @venues do |venue|
  json.partial! 'base', venue: venue
end
