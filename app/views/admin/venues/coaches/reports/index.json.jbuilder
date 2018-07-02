json.coach_reports do
  # we have to provide an ID to any entity we want to denormalize in the future;
  # in this case, we fake report id with coach id, as coach can have only 1 report at a time
  json.id @coach.id
  json.reservations @salary_report.reservations.includes(:user, :classification) do |reservation|
    json.(reservation, :id, :user_id, :user_type, :court_id,
                       :hours, :price)
    json.coach_salary reservation.coach_salary(@coach)
    json.coach_salary_paid reservation.coach_salary_paid(@coach)
    json.start_time TimeSanitizer.output(reservation.start_time)
    json.end_time TimeSanitizer.output(reservation.end_time)
    json.group_name reservation.for_group? ? reservation.group.name : nil
    json.classification reservation.classification&.name
  end

  json.courts @salary_report.courts do |court|
    json.(court, :id, :venue_id, :court_name, :sport_name)
  end
end
