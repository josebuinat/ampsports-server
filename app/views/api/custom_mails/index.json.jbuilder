json.mails(@custom_mails) do |mail|
  json.id mail.id
  json.created_at mail.created_at
  json.from mail.from
  json.subject mail.subject
  json.body mail.body
  json.to (mail.recipient_emails)
  json.image_url mail.image.exists? ? mail.image.url : ""
end
