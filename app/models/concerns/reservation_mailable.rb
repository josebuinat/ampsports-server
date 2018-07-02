module ReservationMailable
  extend ActiveSupport::Concern

  # Mailing basics:
  # 1) If something happens that EVERYONE should be notified about, then we use this concern
  #    and collect_everyone_related_to_this_reservation method. E.g. Reservation Update, Cancel.
  # 2) This concern also takes care of mailing entities which reside in the reservation table.
  #    That is user (owner). We mail owner on create
  # 3) All 1 to many relations, such as Participants should have their own callbacks and mail
  #     all recipients within their own callbacks
  included do
    attr_accessor :skip_booking_mail
    attr_accessor :override_should_send_emails
    after_create :booking_mail, unless: 'skip_booking_mail'
    after_save   :booking_update_email, on: :update
  end

  def skip_booking_mail!
    self.skip_booking_mail = true
  end

  private

  # Participants, owner, coaches. Need to batch-send them updates, such as "reservation cancelled"
  def collect_everyone_related_to_this_reservation
    party_people = participants + participations.active.includes(:user).map(&:user)
    owners = [user]
    (party_people + owners + coaches).uniq.select do |entity|
      # We are not interested in Guests
      [User, Coach, Group].any?(&entity.method(:is_a?))
    end
  end

  def booking_mail
    unless guest_user? || membership?
      ReservationMailer.reservation_created_for_owner(
        user, self, override_should_send_emails: override_should_send_emails
      ).deliver_later
    end
    if online? && company.copy_booking_mail_to.present?
      ReservationMailer.reservation_created_for_owner(
        user, self, send_copy_to: company.copy_booking_mail_to,
        override_should_send_emails: override_should_send_emails
      ).deliver_later
    end
  end

  def booking_update_email
    # Why: due to callback hell reservation re-saves many times, but start_time_was remains nil
    # we need real "updates", not callback-hell updates after create
    was_created_in_memory = (start_time_was.blank? && end_time_was.blank? && court_id_was.blank?)
    return if inactive? || membership? || was_cancelled? || was_created_in_memory

    if timeslot_changed?
      collect_everyone_related_to_this_reservation.each do |recipient|
        ReservationMailer.reservation_updated(
          recipient, self, override_should_send_emails: override_should_send_emails
        ).deliver_later
      end
    end
  end

end
