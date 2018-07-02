json.reservations @reservations do |reservation|
  json.(reservation, :id, :user_id, :user_type, :court_id, :color)
  json.venue_id reservation.venue.id
  json.start TimeSanitizer.output(reservation.start_time)
  json.end TimeSanitizer.output(reservation.end_time)
  json.user_name reservation.user&.full_name

  if reservation.for_group?
    json.participations_count reservation.participations_count
    json.group do
      json.(reservation.group, :name, :max_participants)
    end
  end
end

json.courts @courts do |court|
  json.partial! 'admin/venues/courts/base', court:  court
  json.partial! 'admin/venues/courts/shared_courts', for_court: court
end
