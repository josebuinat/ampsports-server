json.errors @membership.errors

invalid_reservations = @membership.reservations.select { |x| x.invalid? && !x.destroyed? }
if invalid_reservations.present?
  json.reservation_errors invalid_reservations do |reservation|
    json.start_time TimeSanitizer.output(reservation.start_time)
    json.end_time TimeSanitizer.output(reservation.end_time)
    json.court_name reservation.court.court_name
    json.errors reservation.errors.full_messages
  end
end
