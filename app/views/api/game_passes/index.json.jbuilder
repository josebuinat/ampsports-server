json.game_passes(@game_passes) do |game_pass|
  json.id game_pass.id
  json.user game_pass.user
  json.total_charges game_pass.total_charges
  json.remaining_charges game_pass.remaining_charges
  json.active game_pass.active.to_s
  json.price game_pass.price
  json.court_sports game_pass.court_sports_to_s
  json.court_surfaces game_pass.court_surfaces_to_s
  json.court_type Court.human_attribute_name("court_name.#{game_pass.court_type}")
  json.dates_limit game_pass.dates_limit
  json.start_date game_pass.start_date_to_s
  json.end_date game_pass.end_date_to_s
  json.time_limitations game_pass.time_limitations_to_s
  json.currency_unit game_pass.company.currency_unit
  json.currency game_pass.company.currency
  json.coach_ids @game_pass.coach_ids
  json.coach_names game_pass.coaches.map(&:full_name)
end
