class MailPreview < ActionMailer::Preview

  def cancellation
    reservation = Reservation.last
    CancellationMailer.cancellation_email(reservation.user, reservation)
  end

  def card_reminder
    venue_id = Venue.select(:id).joins(:users).group("venues.id, users.id").having("count(users.id) > 0").limit(1).pluck(:id).first
    venue = Venue.find(venue_id)
    UserMailer.membership_card_reminder(venue.users.first, venue)
  end

  def custom_mail
    custom_mail = CustomMail.first
    CustomMailer.custom_mail(custom_mail, 'test@example.com')
  end

  def invoice
    invoice = Invoice.last
    InvoiceMailer.invoice_email(invoice.owner, invoice)
  end

  def undo_send
    invoice = Invoice.last
    InvoiceMailer.undo_send_email(invoice.owner, invoice)
  end

  def support
    SupportMailer.support_email('A title', 'Some content', 'sender@example.com', 'A company')
  end

  def confirmation_instructions
    user = User.last
    ConfirmationMailer.confirmation_instructions(user, 'token', opts = {})
  end

end