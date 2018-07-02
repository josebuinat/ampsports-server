is_owner = current_user.id == reservation.user_id

json.id reservation.id
json.booking_type reservation.booking_type
json.court reservation.court
json.month TimeSanitizer.strftime(reservation.start_time, '%B')
json.day TimeSanitizer.strftime(reservation.start_time, '%d')
json.year TimeSanitizer.strftime(reservation.start_time, '%Y')
json.start_time TimeSanitizer.strftime(reservation.start_time, :time)
json.end_time TimeSanitizer.strftime(reservation.end_time, :time)
json.start_time_iso8601 reservation.start_time.iso8601
json.end_time_iso8601 reservation.end_time.iso8601
json.price number_to_currency(reservation.price_for(current_user))
json.calendarLink api_reservation_download_url(reservation, format: :ics)
json.isRecurring reservation.recurring?
json.isFuture reservation.future?
json.isReselling reservation.reselling?
json.isResold reservation.resold?
json.isPaid reservation.is_paid
json.isOwned json.isOwned is_owner

if reservation.unpaid?
  json.payment_type t('users.show.reservation_unpaid')
else
  json.payment_type t('users.show.reservation_paid')
end

if reservation.cancelable? && (is_owner || reservation.participation_for(current_user))
  json.cancelLink api_reservation_path(reservation)
else
  json.cancelMessage t('users.show.cant_cancel_reservation_message',
                       time: reservation.court.venue.cancellation_time,
                       venue: reservation.court.venue.venue_name)
end
