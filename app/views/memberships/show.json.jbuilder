json.membership do
  json.start_time TimeSanitizer.strftime(@membership.start_time, :time)
  json.end_time TimeSanitizer.strftime(@membership.end_time, :time)
  json.start_date TimeSanitizer.strftime(@membership.start_time, :date)
  json.end_date TimeSanitizer.strftime(@membership.end_time, :date)
  json.price @membership.price
  json.update_url venue_membership_path(@membership.venue, @membership)
  json.courts @membership.courts.pluck(:id)
  json.weekday @membership.reservations_weekday
  json.title @membership.title
  json.note @membership.note
end
