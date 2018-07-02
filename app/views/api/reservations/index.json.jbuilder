json.reservations_past do
  json.partial! 'reservation_array', reservations: @reservations_past
end

json.reservations_future do
  json.partial! 'reservation_array', reservations: @reservations_future
end

json.recurring_past do
  json.partial! 'reservation_array', reservations: @recurring_past
end

json.recurring_future do
  json.partial! 'reservation_array', reservations: @recurring_future
end

json.recurring_reselling_past do
  json.partial! 'reservation_array', reservations: @recurring_reselling_past
end

json.recurring_reselling_future do
  json.partial! 'reservation_array', reservations: @recurring_reselling_future
end

json.recurring_resold_past do
  json.partial! 'reservation_array', reservations: @recurring_resold_past
end

json.recurring_resold_future do
  json.partial! 'reservation_array', reservations: @recurring_resold_future
end

json.recurring_and_regular_reservations_future do
  json.partial! 'reservation_array', reservations: @recurring_and_regular_reservations_future
end

json.recurring_and_regular_reservations_past do
  json.partial! 'reservation_array', reservations: @recurring_and_regular_reservations_past
end

json.lessons_past do
  json.partial! 'reservation_array', reservations: @lessons_past
end

json.lessons_future do
  json.partial! 'reservation_array', reservations: @lessons_future
end
