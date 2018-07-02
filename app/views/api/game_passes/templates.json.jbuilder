@templates.each do |template|
  json.set! template.id do
    json.id template.id
    json.name template.name
    json.template_name template.template_name
    json.total_charges template.total_charges
    json.price template.price
    json.court_sports template.court_sports
    json.court_surfaces template.court_surfaces
    json.court_type template.court_type
    json.start_date template.start_date_to_s
    json.end_date template.end_date_to_s
    json.time_limitations template.time_limitations
    json.currency_unit template.company.currency_unit
    json.currency template.company.currency
    json.coach_ids @game_pass.coach_ids
    json.coach_names game_pass.coaches.map(&:full_name)
  end
end
