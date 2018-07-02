class Reservation::CoachConnection < ActiveRecord::Base
  belongs_to :reservation, required: true, inverse_of: :coach_connections
  belongs_to :coach, required: true

  validates :coach_id, uniqueness: { scope: :reservation_id }

  before_create :calculate_and_set_salary
  after_destroy :send_cancellation_email
  after_create :send_welcome_email

  def calculate_and_set_salary
    return if salary.present?
    self.salary = coach.calculate_salary(reservation.court,
                                         reservation.start_time,
                                         reservation.end_time)
  end

  def mark_salary_paid
    update_attribute(:salary_paid, true)
  end

  private

  def send_cancellation_email
    # we mail coach which was removed from the reservation;
    # if the reservation itself cancelled, this method does not run
    # (because #cancel does not remove the reservation)
    ReservationMailer.coach_removed(
      coach, reservation, override_should_send_emails: reservation.override_should_send_emails
    ).deliver_later
  end

  def send_welcome_email
    # we skip booking mail for memberships
    return if reservation.skip_booking_mail
    ReservationMailer.coach_added(
      coach, reservation, override_should_send_emails: reservation.override_should_send_emails
    ).deliver_later
  end
end
