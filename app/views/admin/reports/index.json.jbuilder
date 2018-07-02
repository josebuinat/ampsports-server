json.revenue do
  json.total @revenue.total
  json.groups @revenue.chunks.to_a.sort { |a,b| a[1] <=> b[1] } do |chunk|
    json.factor chunk[0]
    json.product chunk[1]
  end
end

json.partial! 'utilization', utilization: @utilization

json.bookings do
  json.(@bookings, :paid_on_reservation, :paid_on_site, :booked_by_user_count,
    :booked_by_admin_count, :paid_on_reservation_count, :paid_on_site_count,
    :invoiced_count, :unpaid_count, :to_be_invoiced_count)
end

json.unsold do
  json.hours_count @unsold.summary[:hours]
  json.total @unsold.summary[:profit]
end
