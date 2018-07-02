class Reservation::ParticipantConnection < ActiveRecord::Base
  # Temporary fix
  attr_accessor :skip_association_with_venue

  belongs_to :user, required: true
  belongs_to :reservation, required: true, inverse_of: :participant_connections

  after_create :associate_with_venue, unless: :skip_association_with_venue
  after_create :send_mail_on_create
  after_destroy :send_mail_on_destroy

  validates :user_id, uniqueness: { scope: :reservation_id }

  before_save :inherit_data_from_reservation, if: :the_only_participant?

  # Reservation price should always be equal to sum of the participant prices;
  # Safe to delete if we would not see any errors
  after_save :validate_data_integrity
  private

  def the_only_participant?
    # inverse_of takes care of not-yet created entities; it's safe to ask the count BEFORE they are saved
    reservation.participant_connections.one?
  end

  def no_participants?
    reservation.participant_connections.none?
  end

  def inherit_data_from_reservation
    self.amount_paid = reservation.amount_paid
    self.price = reservation.price
  end

  def associate_with_venue
    reservation.venue.venue_user_connectors.create user_id: user_id
  end

  def validate_data_integrity
    price_of_all_participations = reservation.participant_connections.map(&:price).inject(&:+)
    if reservation.price != price_of_all_participations
      Rollbar.warn("Sum of participations is not equal to the reservation price!",
        price_of_all_participations: price_of_all_participations,
        reservation_price: reservation.price,
        reservation_id: reservation.id,
      )
    end
  end

  def send_mail_on_create
    # If User is the owner of the reservation, then we don't mail him. (He will receive mail for the Owner)
    return if reservation.user == user
    # Notify the participant that he is a participant
    ReservationMailer.participant_added_for_participant(
      user, reservation, override_should_send_emails: reservation.override_should_send_emails
    ).deliver_later
    # Notify a coach that we have a new participant
    reservation.coaches.each do |coach|
      ReservationMailer.participant_added_for_coach(
        coach, reservation, entity: user, override_should_send_emails: reservation.override_should_send_emails
      ).deliver_later
    end
  end

  def send_mail_on_destroy
    # Do not mix this up with the whole reservation cancellation.
    # It's just a 1 guy who gets removed.
    ReservationMailer.participant_removed_for_participant(
      user, reservation, override_should_send_emails: reservation.override_should_send_emails
    ).deliver_later
    reservation.coaches.each do |coach|
      ReservationMailer.participant_removed_for_coach(coach, reservation,
        entity: user, override_should_send_emails: reservation.override_should_send_emails).deliver_later
    end
  end
end
