json.venues(@venues) do |venue|
  json.(venue, :id, :venue_name)
  json.email_subscription current_user.subscription_enabled?(venue)
  json.image_thumbnail venue.try_photo_url
  json.image_small venue.try_photo_url(:small)
end
