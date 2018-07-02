json.updated_memberships_count @updated.size

json.invalid_memberships @failed do |membership|
  json.(membership, :title)
  json.owner_full_name membership.user.full_name
  json.errors membership.errors.full_messages
  json.invalid_reservations membership.reservations.select(&:invalid?) do |reservation|
    json.start_time TimeSanitizer.output(reservation.start_time)
    json.end_time TimeSanitizer.output(reservation.end_time)
    json.court_name reservation.court.court_name
    json.errors reservation.errors.full_messages
  end
end
