# Loops through the recipient emails and sends individual mails
class CustomMailWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(custom_mail_id)
    custom_mail = CustomMail.find(custom_mail_id)
    custom_mail.recipient_emails.each do |recipient_email|
      begin
        CustomMailer.custom_mail(custom_mail, recipient_email).deliver_now
      rescue => e
        Rollbar.error(e, 'Error while sending custom email',
                      to: recipient_email,
                      custom_mail_id: custom_mail_id
        )
      end
    end
    # TODO count actual number of mails sent
    logger.info "  Sent #{custom_mail.recipient_emails.count} mails."
  end
end
