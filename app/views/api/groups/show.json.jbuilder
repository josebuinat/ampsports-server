json.partial! 'base', group: @group

json.members(@group.members) do |member|
  json.partial! 'api/users/base', user: member.user
end

json.reservations(@group.reservations) do |reservation|
  json.partial! 'api/reservations/reservation', reservation: reservation
end
