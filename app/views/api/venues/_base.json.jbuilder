json.(venue, :id , :latitude, :longitude, :venue_name, :website, :phone_number, :street, :timezone,
             :city, :zip, :status, :max_consecutive_bookable_hours, :max_bookable_hours_per_day, :cancellation_time)
json.url api_venue_path(venue, format: :json)
json.image venue.try_photo_url
json.image_small venue.try_photo_url(:small)
json.currency_unit venue.company.currency_unit
json.currency venue.company.currency
json.country venue.country.name
json.country_code venue.country.iso_2
