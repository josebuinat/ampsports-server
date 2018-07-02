json.shared_courts for_court.shared_courts do |court|
  json.partial! 'base', court: court
end
