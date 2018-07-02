json.reservations @reservations do |reservation|
  json.partial! 'base', reservation: reservation
end
