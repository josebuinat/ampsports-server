json.custom_emails @custom_mails do |custom_mail|
  json.partial! 'base', custom_mail: custom_mail
  json.recipient_emails custom_mail.recipient_emails
end
