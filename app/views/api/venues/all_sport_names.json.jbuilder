json.sportnames @sport_names do |sport_name|
  json.sport sport_name
  json.localized_name Court.human_attribute_name("sport_name.#{sport_name}")
  json.url do
    json.active asset_path("sport_icons/active/#{sport_name}.svg")
    json.inactive asset_path("sport_icons/inactive/#{sport_name}.svg")
  end
end
