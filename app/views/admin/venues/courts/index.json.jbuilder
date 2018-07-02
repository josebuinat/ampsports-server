json.courts @courts do |court|
  json.partial! 'base', court: court
  # shared_courts is not inside "base" partial because shared_courts use base partial by itself
  json.partial! 'shared_courts', for_court: court
end

json.partial! 'shared/pagination', collection: @courts
