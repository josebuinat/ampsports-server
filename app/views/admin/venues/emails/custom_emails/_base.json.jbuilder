json.(custom_mail, :id, :from, :subject, :body)
json.created_at custom_mail.created_at.to_s(:date_time)
json.image_url custom_mail.image&.url.to_s
