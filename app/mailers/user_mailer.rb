class UserMailer < ApplicationMailer
  def membership_card_reminder(user, venue)
    @user = user
    @venue = venue

    I18n.with_locale(user.locale) do
      Time.with_user_clock_type(user) do
        mail(
          to: @user.email,
          subject: t('.credit_card_reminder')
        )
      end
    end
  end
end
