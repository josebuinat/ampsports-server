json.logs @logs do |log|
  json.(log, :id, :params)
  json.created_at TimeSanitizer.output(log.created_at)
  json.updated_at TimeSanitizer.output(log.updated_at)
  json.payment_type t_enum(:reservation, :payment_type, log.params[:payment_type])
  json.booking_type t_enum(:reservation, :booking_type, log.params[:booking_type])
  json.status t_enum(:reservations_log, :status, log.status)
  json.court_name log.reservation.court.court_name
end
