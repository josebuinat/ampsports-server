json.partial! 'base', participation_credit: @participation_credit
json.applicable_reservations(@applicable_reservations) do |reservation|
  json.partial! 'api/reservations/reservation', reservation: reservation
  json.group do
    json.partial! 'api/groups/base', group: reservation.group
  end
end
