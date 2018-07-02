class ConfirmationMailer < Devise::Mailer
  helper :application, MailersHelper

  default template_path: 'devise/mailer'

  def confirmation_instructions(record, token, opts = {})
    @venue = record.try(:venues).try(:first)

    I18n.with_locale(record.try(:locale)) do
      if @venue.present?
        opts[:subject] = t('devise.mailer.user_with_venue.user_created',
                            venue: @venue.venue_name)
      end
      super(record, token, opts)
    end
  end

  def devise_mail(record, action, opts = {})
    I18n.with_locale(record.try(:locale)) do
      super(record, action, opts)
    end
  end
end
