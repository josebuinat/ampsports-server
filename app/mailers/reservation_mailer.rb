# Send email confirmations for changes in reservations
class ReservationMailer < ApplicationMailer
  add_template_helper ApplicationHelper
  add_template_helper LayoutsHelper

  # reservation_cancelled is handled by cancellation mailer
  reservation_actions = %i(
    reservation_created_for_owner
    reservation_updated
    participant_added_for_coach
    participant_added_for_participant
    participant_removed_for_coach
    participant_removed_for_participant
    coach_added
    coach_removed
  )

  def self.subject_for_reservation(reservation, method_name)
    I18n.t("reservation_mailer.#{method_name}.subject",
      venue_name: reservation.venue.venue_name,
      date: I18n.l(TimeSanitizer.output(reservation.start_time), format: :easy))
  end

  def self.comment_for_reservation(method_name, entity)
    hash = entity ? { user_name: entity.full_name } : { }
    I18n.t("reservation_mailer.#{method_name}.description", hash)
  end

  reservation_actions.each do |method_name|
    # recipient is that one who will receive the message. Entity is usually that one who caused that to happen
    # For instance, message to coach (coach = recipient) that User Bobby was added as a participant to the reservation
    # (User Bobby = entity)
    define_method method_name do |recipient, reservation, entity: nil, send_copy_to: nil, override_should_send_emails: nil|
      # override_should_send_emails completely overrides the setting should we email or not
      # if its value is `nil`, then we fallback to company level settings and send (or don't) based on that
      # if it has a value (true or false) then we send email or we don't respectively
      should_send_emails = if override_should_send_emails.nil?
        !disabled_company_level_email(reservation.company, method_name)
      else
        !!override_should_send_emails
      end
      return unless should_send_emails
      return if disabled_reservation_email_by_user(recipient, method_name)

      prepare_instance_variables(reservation, recipient) do
        @comment = self.class.comment_for_reservation(method_name, entity)
        mail(to: send_copy_to || @user.email,
          template_name: 'reservation_mail',
          subject: self.class.subject_for_reservation(reservation, method_name.to_s))
      end
    end
  end

  private

  def prepare_instance_variables(reservation, user, &block)
    @user = user
    @reservation = reservation
    # have to assign @venue, because _footer_address partial needs it
    @venue = @reservation.venue
    I18n.with_locale(user.locale) do
      Time.with_user_clock_type(user) do
        yield if block_given?
      end
    end
  end
end
