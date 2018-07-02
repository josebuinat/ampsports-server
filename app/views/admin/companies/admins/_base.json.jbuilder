json.(admin, :id, :first_name, :last_name, :full_name, :email, :level,
  :admin_birth_day, :admin_birth_month, :admin_birth_year, :level_to_s, :clock_type)

json.birth_date admin.birth_date&.strftime('%Y-%m-%d')
