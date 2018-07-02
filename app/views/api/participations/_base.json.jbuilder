json.(participation, :id, :is_paid, :billing_phase, :price, :created_at, :updated_at)
json.reservation do
  json.partial! 'api/reservations/reservation', reservation: participation.reservation
end
json.group do
  json.partial! 'api/groups/base', group: participation.reservation.group
end
