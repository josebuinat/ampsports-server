class InvoiceComponent < ActiveRecord::Base
  include Taxable
  include Billable

  belongs_to :invoice
  belongs_to :reservation
  has_one :company, through: :invoice
  has_one :court, through: :reservation
  has_one :user, through: :reservation
  has_many :coaches, through: :reservation
  delegate :start_time, to: :reservation, allow_nil: true
  delegate :end_time, to: :reservation, allow_nil: true
  delegate :court_name, to: :court
  delegate :sport, to: :court, allow_nil: true

  scope :user, ->(user) {
    joins(:invoice).where(invoices: { owner_id: user.id, owner_type: user.class.name })
  }

  # define product for Billable
  alias product reservation

  # overriden method from Billable
  def update_product?
    reservation.present? && not_resold?
  end

  # overriden method from Billable
  def mark_paid!
    Invoice.transaction do
      if update_product?
        reservation.update_attribute(:amount_paid, reservation.price)
      end
      update_attribute(:is_paid, true)
    end
  end

  def self.build_from(reservations)
    reservations.map do |reservation|
      new(
        reservation: reservation,
        price: reservation.outstanding_balance,
        start_time: reservation.start_time,
        end_time: reservation.end_time
      )
    end
  end

  private

  def not_resold?
    invoice.owner == reservation.user
  end
end
