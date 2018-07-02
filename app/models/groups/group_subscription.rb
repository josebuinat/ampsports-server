#represents user participation in the group reservation
class GroupSubscription < ActiveRecord::Base
  enum billing_phase: [:not_billed, :drafted, :billed]

  belongs_to :user
  belongs_to :group_season
  has_many :group_subscription_invoice_components, dependent: :destroy
  has_one :group, through: :group_season
  has_one :venue, through: :group
  has_one :company, through: :venue
  delegate :start_date, :end_date, :start_time, :end_time, :current, to: :group_season

  before_validation :set_price

  validates :user, :group_season, :price, presence: true

  before_save :set_is_paid, unless: :is_paid?
  after_save :delete_invoice_components, if: :was_cancelled?
  after_save :mark_paid_participations, if: :was_paid?
  after_save :mark_unpaid_participations, if: :was_unpaid?

  scope :invoiceable, -> { not_billed.active.where(is_paid: false) }
  scope :active, -> { where(cancelled: false) }
  scope :cancelled, -> { where(cancelled: true) }

  # reservations related to this season
  def reservations
    group.reservations.between(start_time, end_time)
  end

  def cancel
    update_attribute(:cancelled, true) if cancelable?
  end

  def mark_paid(amount = nil)
    if payable?
      if amount.present? && amount.to_d < price
        update(amount_paid: amount.to_d)
      else
        update(is_paid: true)
      end
    end
  end

  def mark_unpaid
    update(amount_paid: 0, is_paid: false) if unpayable?
  end

  def payable?
    !is_paid? && not_billed?
  end

  def unpayable?
    is_paid? && not_billed?
  end

  def cancelable?
    !cancelled
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

  def amount_paid
    is_paid? ? price : (self[:amount_paid] || 0.to_d)
  end

  def outstanding_balance
    price - amount_paid
  end

  private

  def set_price
    return unless group_season.present?

    self.price ||= group_season.get_participation_price
  end

  def set_is_paid
    self.is_paid = true if amount_paid >= price
  end

  def was_cancelled?
    cancelled_changed? && cancelled?
  end

  def delete_invoice_components
    invoices = group_subscription_invoice_components.map(&:invoice)

    GroupSubscriptionInvoiceComponent.without_undraft_callback do
      group_subscription_invoice_components.destroy_all
    end

    invoices.each(&:calculate_total!)
  end

  def was_paid?
    is_paid_changed? && is_paid?
  end

  def was_unpaid?
    is_paid_changed? && !is_paid?
  end

  def mark_paid_participations
    reservations.each do |reservation|
      reservation.participations.where(user: user).update_all(is_paid: true)
    end
  end

  def mark_unpaid_participations
    reservations.each do |reservation|
      reservation.participations.where(user: user).update_all(is_paid: false)
    end
  end
end
