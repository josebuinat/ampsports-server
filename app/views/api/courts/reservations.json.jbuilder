Time.use_zone(@timezone) do
  json.reservations @reservations do |reservation|
    json.partial! 'reservation', reservation: reservation
  end
end
