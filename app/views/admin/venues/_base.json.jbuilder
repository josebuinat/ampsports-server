json.(venue, :id, :venue_name, :latitude, :longitude, :description, :parking_info,
  :transit_info, :website, :phone_number, :company_id, :created_at, :updated_at,
  :street, :city, :zip, :booking_ahead_limit, :status, :primary_photo_id,
  :cancellation_time, :invoice_fee, :allow_overlapping_resell,
  :max_consecutive_bookable_hours, :max_bookable_hours_per_day,
  :confirmation_message, :registration_confirmation_message,
  :custom_colors, :user_colors, :discount_colors, :classification_colors, :group_colors,
  :coach_colors, :business_hours, :timezone)

json.courts_count venue.courts.count
json.users_count venue.users.count
json.primary_photo_url venue.primary_photo&.image&.url
json.country_code venue.country.code
