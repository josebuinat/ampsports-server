json.partial! 'admin/reservations/base', reservation: @reservation

# why not partial? Because user is polymorphic and it's easier to ducktype
user = @reservation.user
json.full_name user&.full_name
json.phone_number user.respond_to?(:phone_number) ? user.phone_number : nil

# Most likely we don't need participant_ids anymore to send here
json.participant_ids @reservation.participant_ids

json.participant_connections @reservation.participant_connections.includes(:user) do |connection|
  json.(connection, :id, :user_id, :reservation_id, :price, :amount_paid)
  json.full_name connection.user.full_name
end

json.calculated_price @reservation.calculate_price
