json.(membership, :id, :user_id, :venue_id, :created_at,
  :updated_at, :price, :invoice_by_cc, :title, :note, :reservations_fingerprint)

json.start_time TimeSanitizer.output(membership.start_time)
json.end_time TimeSanitizer.output(membership.end_time)
json.weekday membership.reservations_weekday


json.user do
  user = membership.for_group? ? membership.group.owner : membership.user
  if user.is_a? Admin
    json.partial! 'admin/companies/admins/base', admin: user
  else
    json.partial! 'admin/users/base', user: user
  end
end

if membership.for_group?
  json.group do
    json.partial! 'admin/venues/groups/base', group: membership.group
  end
end

json.reservations membership.reservations.sort_by(&:start_time) do |reservation|
  json.partial! 'admin/reservations/base', reservation: reservation
end

json.courts membership.courts do |court|
  json.partial! 'admin/venues/courts/base', court: court
end
