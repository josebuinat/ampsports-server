class ApplicationMailer < ActionMailer::Base
  helper MailersHelper
  layout 'mailer'
  default from: "no-reply@playven.com"

  protected

  # this vast variety of different mailer actions are fully controlled by `user.email_notifications`
  # key is the mailer action name. Value is the User#email_notifications setting.
  # `nil` means there's no company setting for that (same effect is key is missing on that hash)
  def user_email_notifications_map
    {
      user_cancellation_email: :reservation_cancellations,
      admin_cancellation_email: :reservation_cancellations,

      reservation_created_for_owner: :reservation_receipts,
      reservation_updated: :reservation_updates,
      participant_added_for_participant: :reservation_receipts,
      participant_removed_for_participant: :reservation_cancellations,
      coach_added: :reservation_updates,
      coach_removed: :reservation_updates,

      membership_created: :reservation_receipts,
      membership_updated: :reservation_updates,
    }.with_indifferent_access
  end

  def disabled_reservation_email_by_user(user, action)
    return false unless user.is_a?(User)

    setting_name = user_email_notifications_map[action.to_sym]

    return false if setting_name.blank?
    !user.email_notifications.get(setting_name)

  end

  def disabled_company_level_email(company, action)
    enabled = company.email_notifications.get(action)
    !enabled
  end
end
