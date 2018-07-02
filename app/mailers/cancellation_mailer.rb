class CancellationMailer < ApplicationMailer
  def admin_cancellation_email(user, reservation, override_should_send_emails: nil)
    return if disabled_reservation_email_by_user(user, :admin_cancellation_email)

    @user = user
    @reservation = reservation
    @venue = @reservation.court.venue
    # return unless company_allows_mailing?(@venue.company, :admin_cancellation_email, override_should_send_emails)
    should_mail = if override_should_send_emails.nil?
      !disabled_company_level_email(@venue.company, :admin_cancellation_email)
    else
      override_should_send_emails
    end

    return unless should_mail
    venue_name = @venue.venue_name

    I18n.with_locale(user.locale) do
      Time.with_user_clock_type(user) do
        @reservation_date = @reservation.start_time.to_s(:date)

        mail(
          to: @user.email,
          subject: t('.subject',
                      start: @reservation_date,
                      venue: venue_name)
        )
      end
    end
  end

  def user_cancellation_email(user, reservation, override_should_send_emails: nil)
    return if override_should_send_emails == false # strict check on false, we don't return on nil!
    return if disabled_reservation_email_by_user(user, :user_cancellation_email)

    @user = user
    @reservation = reservation
    @venue = @reservation.court.venue
    venue_name = @venue.venue_name

    I18n.with_locale(user.locale) do
      Time.with_user_clock_type(user) do
        @reservation_date = @reservation.start_time.to_s(:date)

        mail(
          to: @user.email,
          subject: t('.subject',
                      start: @reservation_date,
                      venue: venue_name)
        )
      end
    end
  end

  private

end
