class CustomMailer < ApplicationMailer

  # Custom mail created and sent by admin
  def custom_mail(custom_mail, to)
    @body = custom_mail.body
    @image_url = custom_mail.image.exists? ?
                custom_mail.image.url :
                custom_mail.venue.try(:primary_photo).try(:image).try(:url)

    mail(
      to: to,
      subject: custom_mail.subject,
      from: custom_mail.from
    )
  end
end
