json.partial! 'base', holiday: @holiday

json.courts @holiday.courts do |court|
  json.partial! 'admin/venues/courts/base', court: court
end

if @holiday.conflicting_reservations.present?
  json.conflicting_reservations @holiday.conflicting_reservations do |reservation|
    json.partial! 'admin/reservations/base', reservation: reservation
  end
end
