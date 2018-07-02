json.(reservation, :id, :user_id, :user_type, :date, :price, :total, :created_at, :updated_at,
  :court_id, :is_paid, :user_type, :charge_id, :participations_count, :classification_id,
  :refunded, :payment_type, :booking_type, :note, :initial_membership_id,
  :reselling, :inactive, :billing_phase, :paid_in_full, :coach_ids)

json.amount_paid reservation.amount_paid.to_f

sanitized_start_time = TimeSanitizer.output(reservation.start_time)
json.start_time sanitized_start_time
sanitized_end_time = TimeSanitizer.output(reservation.end_time)
json.end_time sanitized_end_time

json.start_tact sanitized_start_time.to_s(:time)
json.end_tact sanitized_end_time.to_s(:time)
json.date sanitized_start_time.to_s(:date)

json.has_membership reservation.membership?

json.color reservation.color
json.resold reservation.resold?
json.reselling reservation.reselling?
json.future reservation.future?
json.refundable reservation.refundable_by_admin?
# having court_id along with court.id is easier for frontend to catch up
json.court_id reservation.court.id
json.court do
  json.partial! 'admin/venues/courts/base', court: reservation.court
end

json.owner_name reservation.owner_name

json.coach_name reservation.coaches.map(&:full_name).join(', ')

if reservation.for_group?
  json.group do
    json.(reservation.group, :name, :max_participants, :owner_id, :owner_type,
                             :coach_ids, :priced_duration)
  end
end
