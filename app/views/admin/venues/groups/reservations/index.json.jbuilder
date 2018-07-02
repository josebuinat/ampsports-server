json.reservations(@reservations) do |reservation|
  json.partial! 'admin/reservations/base', reservation: reservation
end
