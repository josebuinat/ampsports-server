json.user do
  json.id reservation.user.id
  json.name reservation.user.full_name
  json.first_name reservation.user.first_name
  json.last_name reservation.user.last_name
end
json.id reservation.id
json.booking_type reservation.booking_type
json.court reservation.court.court_name
json.sport reservation.court.sport
json.start_time TimeSanitizer.strftime(reservation.start_time, :time)
json.end_time TimeSanitizer.strftime(reservation.end_time, :time)
json.start_time_iso8601 reservation.start_time.iso8601
json.end_time_iso8601 reservation.end_time.iso8601
json.price number_to_currency(reservation.price)
json.amount_paid number_to_currency(reservation.amount_paid)
json.unpaid_amount number_to_currency(reservation.price - reservation.amount_paid)
if reservation.unpaid?
  json.payment_type t('users.show.reservation_unpaid')
else
  json.payment_type t('users.show.reservation_paid')
end
json.month TimeSanitizer.strftime(reservation.start_time, '%B')
json.day TimeSanitizer.strftime(reservation.start_time, '%d')
json.year TimeSanitizer.strftime(reservation.start_time, '%Y')
