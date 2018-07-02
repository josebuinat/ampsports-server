json.(price, :id, :price, :created_at, :updated_at,
  :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday,
  :start_minute_of_a_day, :end_minute_of_a_day)

date = params[:start].present? ? TimeSanitizer.input(params[:start]) : Date.current
formatted_date = date.strftime('%d/%m/%Y')
# why not TimeSanitizer#input? Because we are interested in hours:minutes only,
# and date here is just to satisfy full calendar
json.start Time.zone.parse("#{formatted_date} #{price.start_time.to_s(:time)}")
json.end Time.zone.parse("#{formatted_date} #{price.end_time.to_s(:time)}")

json.court_ids price.court_ids
json.days price.days
