json.array! @subscriptions do |reservation|
  venue = reservation.court.venue
  @current_company = venue.company
  json.venue do
    json.link venue_path(venue)
    json.imageUrl venue.try(:primary_photo).try(:image).try(:url)
    json.street venue.street
    json.zip venue.zip
    json.city venue.city
    json.phone_number venue.phone_number
    json.website venue.website
    json.name venue.venue_name
  end
  json.id reservation.id
  json.booking_type reservation.booking_type
  json.court reservation.court
  json.month TimeSanitizer.strftime(reservation.start_time, '%B')
  json.day TimeSanitizer.strftime(reservation.start_time, '%d')
  json.year TimeSanitizer.strftime(reservation.start_time, '%Y')
  json.start_time TimeSanitizer.strftime(reservation.start_time, :time)
  json.end_time TimeSanitizer.strftime(reservation.end_time, :time)
  json.price number_to_currency(reservation.price)
  json.calendarLink venue_reservation_path(venue.id, reservation.id, format: :ics)
  if reservation.unpaid?
    json.payment_type t('users.show.reservation_unpaid')
  else
    json.payment_type t('users.show.reservation_paid')
  end
  if reservation.cancelable?
    json.cancelLink api_reservation_path(reservation)
  else
    json.cancelMessage t('users.show.cancellation_policy', time: venue.cancellation_time,
                                                           venue: venue.venue_name)
  end
end
