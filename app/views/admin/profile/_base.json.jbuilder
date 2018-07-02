json.(current_admin, :id, :first_name, :last_name, :email, :clock_type, :locale)
json.auth_token current_admin.authentication_payload[:auth_token]
