#represents user participation in the group reservation
class Participation < ActiveRecord::Base
  enum billing_phase: [:not_billed, :drafted, :billed]

  belongs_to :user
  belongs_to :reservation, inverse_of: :participations
  has_many :participation_invoice_components, dependent: :destroy
  has_one :venue, through: :reservation
  has_one :company, through: :venue
  delegate :group, to: :reservation

  validates :user, :reservation, :price, presence: true
  validate :validate_group_reservation
  validate :validate_filled_group_reservation
  validate :validate_one_active_participant

  before_validation :set_price
  after_save :credit_participation, if: :was_cancelled?
  after_save :delete_invoice_components, if: :was_cancelled?
  after_create :update_counter_cache
  after_create :mail_on_create
  after_destroy :update_counter_cache
  after_save :update_counter_cache, if: :was_cancelled?

  scope :invoiceable, -> { not_billed.active.where(is_paid: false) }
  scope :active, -> { where(cancelled: false) }
  scope :cancelled, -> { where(cancelled: true) }
  scope :reservation_includes, -> do
    includes(reservation: [
      :membership,
      court: :venue,
      user: [:owner, :coaches, :classification, :seasons]
    ])
  end

  # Used instead of `destroy`
  def cancel
    return false if cancelled?
    update_attribute(:cancelled, true)

    mail_on_cancel

    true
  end

  def mark_paid
    update_attribute(:is_paid, true) if payable?
  end

  def payable?
    !is_paid? && not_billed? && !group.season?
  end

  def status
    if is_paid?
      'paid'
    elsif billing_phase != 'not_billed'
      billing_phase
    elsif cancelled
      'cancelled'
    else
      'unpaid'
    end
  end

  private

  def mail_on_cancel
    ReservationMailer.participant_removed_for_participant(
      user, reservation, override_should_send_emails: reservation.override_should_send_emails
    ).deliver_later
    reservation.coaches.each do |coach|
      ReservationMailer.participant_removed_for_coach(coach, reservation,
        entity: user, override_should_send_emails: reservation.override_should_send_emails).deliver_later
    end
  end

  def mail_on_create
    return if reservation.skip_booking_mail
    ReservationMailer.participant_added_for_participant(
      user, reservation, override_should_send_emails: reservation.override_should_send_emails
    ).deliver_later
    reservation.coaches.each do |coach|
      ReservationMailer.participant_added_for_coach(
        coach, reservation, entity: user, override_should_send_emails: reservation.override_should_send_emails
      ).deliver_later
    end
  end

  def validate_group_reservation
    unless reservation&.for_group?
      errors.add :reservation, :not_a_group_reservation
    end
  end

  def validate_filled_group_reservation
    return unless reservation.present? && reservation.for_group?

    unless reservation.participations.active.count < reservation.group.max_participants
      errors.add :reservation, :filled_group_reservation
    end
  end

  def validate_one_active_participant
    return unless reservation.present? && reservation.for_group?

    if reservation.participations.active.where(user: user).any?
      errors.add :reservation, :already_participating
    end
  end

  def set_price
    return unless reservation.present?

    self.price = reservation.participation_price unless price.present?
  end

  def was_cancelled?
    cancelled_changed? && cancelled?
  end

  def credit_participation
    return unless is_paid? || billed?

    case group.cancellation_policy
    when 'participation'
      add_to_participation_credit!
    when 'refund'
      add_to_credit_balance!
    end
  end

  def add_to_participation_credit!
    ParticipationCredit.create!(
      user: user,
      company: company,
      group_classification: group.classification
    )
  end

  def add_to_credit_balance!
    Credit.create!(
      user: user,
      company: company,
      balance: crediting_price
    )
  end

  def crediting_price
    if participation_invoice_components.any?
      participation_invoice_components.sum(:price)
    else
      price
    end
  end

  def delete_invoice_components
    invoices = participation_invoice_components.map(&:invoice)

    ParticipationInvoiceComponent.without_undraft_callback do
      participation_invoice_components.destroy_all
    end

    invoices.each(&:calculate_total!)
  end

  def update_counter_cache
    self.reservation.update_participations_count
  end
end
