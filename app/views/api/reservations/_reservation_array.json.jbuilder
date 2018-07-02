_dates = reservations.map do |reservation|
  venue = reservation.venue
  Time.use_zone(venue.timezone) do
    reservation.start_time.in_time_zone.to_date
  end
end.uniq

json.dates _dates do |date|

  date_reservations = reservations.select do |reservation|
    venue = reservation.venue
    Time.use_zone(venue.timezone) do
      reservation.start_time.in_time_zone.to_date == date
    end
  end

  company = date_reservations.first.company

  json.date l(date, format: "%Y-%m-%d")
  json.courts date_reservations.count
  json.total date_reservations.sum { |r| r.price_for(current_user) }
  json.minutes date_reservations.sum { |r| r.end_time - r.start_time } / 60
  json.currency_unit company.currency_unit
  json.currency company.currency

  reservation_grouped_by_venue = date_reservations.group_by { |r| r.venue }

  json.venues reservation_grouped_by_venue do |h|
    _venue = h.first
    _reservations = h.second
    @current_company = _venue.company

    json.(_venue, :venue_name, :cancellation_time)
    json.venue_id _venue.id
    json.venue_photo (_venue.primary_photo&.image&.url || _venue.photos.first&.image&.url)
    json.image_small _venue.try_photo_url(:small)
    json.courts _reservations.count
    json.minutes _reservations.sum { |r| r.end_time - r.start_time } / 60
    json.total _reservations.sum { |r| r.price_for(current_user) }
    _reservations_grouped_by_sport = _reservations.group_by { |r| r.court.sport.underscore }
    json.sports _reservations_grouped_by_sport do |hash|
      json.sport hash.first
      json.courts hash.second.count
      json.reservations hash.second.each do |reservation|
        Time.use_zone(_venue.timezone) do
          json.partial! 'reservation', reservation: reservation
          json.(reservation, :note, :participations_count, :coach_ids)
          json.owner_name reservation.owner_name
          json.coach_name reservation.coaches.map(&:full_name).join(', ')

          if reservation.for_group?
            json.group do
              json.(reservation.group, :name, :max_participants, :owner_id, :owner_type,
                :coach_ids, :priced_duration)
              json.participation_price number_to_currency(reservation.group.participation_price)
              json.classification_name reservation.group.classification.name
            end
          end
        end
      end
    end
  end
end
