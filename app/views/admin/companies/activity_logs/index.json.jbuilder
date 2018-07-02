json.activity_logs(@activity_logs) do |log|
  json.(log, :id, :payload_type, :actor_id, :actor_name, :actor_type, :company_id, :description)

  json.activity_type log.activity_type.humanize
  json.number_of_payloads log.payload_details.size
  json.activity_time TimeSanitizer.output(log.activity_time).strftime('%Y-%m-%d %H:%M')
end

json.pagination do
  json.current_page @activity_logs.current_page
  json.per_page @activity_logs.per_page
  json.total_pages @activity_logs.total_pages
end
