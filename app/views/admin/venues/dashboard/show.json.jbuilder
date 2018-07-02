json.partial! 'admin/reports/utilization', utilization: @utilization_calculator

booked_by_admin_count = @bookings_calculator.booked_by_admin_count
booked_by_user_count = @bookings_calculator.booked_by_user_count
total_bookings = booked_by_admin_count + booked_by_user_count
json.booking_by_user_rate total_bookings.zero? ? 0 : booked_by_user_count.to_f / total_bookings

json.today_revenue do
  json.total @today_revenue_calculator.total
  json.reservations_count @today_revenue_calculator.reservations_count
  json.lost_total @today_unsold_calculator.summary[:profit]
  json.lost_hours @today_unsold_calculator.summary[:hours]
end

json.week_revenue do
  json.total @week_ago_revenue_calculator.total
  json.reservations_count @week_ago_revenue_calculator.reservations_count
  json.lost_total @week_ago_unsold_calculator.summary[:profit]
  json.lost_hours @week_ago_unsold_calculator.summary[:hours]
end
