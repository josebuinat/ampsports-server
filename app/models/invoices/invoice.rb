class Invoice < ActiveRecord::Base
  include Sortable
  virtual_sorting_columns({
    customer_name: {
      joins: <<~SQL,
        left outer join users on (users.id = invoices.owner_id AND invoices.owner_type = 'User')
        left outer join coaches on (coaches.id = invoices.owner_id AND invoices.owner_type = 'Coach')
      SQL
      order: ->(direction) { "users.first_name #{direction}, users.last_name #{direction},
                              coaches.first_name #{direction}, coaches.last_name #{direction}" }
    }
  })

  belongs_to :company
  belongs_to :owner, polymorphic: true
  belongs_to :group_custom_biller
  has_many :invoice_components, dependent: :destroy
  has_many :gamepass_invoice_components, dependent: :destroy
  has_many :custom_invoice_components, dependent: :destroy
  has_many :participation_invoice_components, dependent: :destroy
  has_many :group_subscription_invoice_components, dependent: :destroy
  has_many :reservations, through: :invoice_components
  has_many :activity_logs_payloads_connectors, as: :payload
  has_many :activity_logs, through: :activity_logs_payloads_connectors

  # generally it's a bad idea to modify data in before_ callbacks, but this is just a cache, so it's bearable
  before_validation :calculate_total
  before_create :set_reference_number
  validates_presence_of :total, on: :update
  validates_presence_of :owner

  scope :drafts, -> { where(is_draft: true) }
  scope :viewable_by_user, -> { where(is_draft: false) }
  scope :unpaid, -> { where(is_draft: false, is_paid: false) }
  scope :paid, -> { where(is_draft: false, is_paid: true) }
  scope :components_includes, -> do
    includes(:custom_invoice_components,
             gamepass_invoice_components: [:game_pass, :company],
             participation_invoice_components: [:company, :participation, :reservation, :court, :coaches],
             group_subscription_invoice_components: [:company, :group_subscription, :group],
             invoice_components: [:company, :reservation, :court, :coaches])
  end
  scope :search, ->(term) {
    # can't use joins(:owner) because of polymorphic association
    joins(<<~SQL
        left outer join users on (users.id = invoices.owner_id AND invoices.owner_type = 'User')
        left outer join coaches on (coaches.id = invoices.owner_id AND invoices.owner_type = 'Coach')
      SQL
    ).where('users.first_name ilike :term OR users.last_name ilike :term OR
             coaches.first_name ilike :term OR coaches.last_name ilike :term',
             term: "%#{term}%")
  }

  accepts_nested_attributes_for :custom_invoice_components, allow_destroy: true
  accepts_nested_attributes_for :gamepass_invoice_components, allow_destroy: true
  accepts_nested_attributes_for :invoice_components, allow_destroy: true
  accepts_nested_attributes_for :participation_invoice_components, allow_destroy: true
  accepts_nested_attributes_for :group_subscription_invoice_components, allow_destroy: true

  def biller
    group_custom_biller.present? ? group_custom_biller : company
  end

  def payment_status
    if is_paid?
      'paid'
    elsif is_draft?
      'drafted'
    else
      'billed'
    end
  end

  # resets due_time to default 2 weeks ahead if nil or past
  def due_time=(time)
    if !time || (time < Time.current)
      time = Time.current.advance(weeks: 2)
    end
    super(time)
  end

  # from - to: optional dates
  # if custom_biller supplied it will find only participations and subscriptions related to it
  def self.create_for_company(company, user, from: nil, to: nil, custom_biller: nil)
    if custom_biller.present?
      reservations = game_passes = [] # only participations and subscriptions for biller
    else
      reservations = company.user_reservations(user).invoiceable
      reservations = reservations.between(from.beginning_of_day, to.end_of_day) if from && to
      game_passes = company.game_passes.where(user: user).invoiceable
    end

    participations = company.participations_by_biller(custom_biller).where(user: user).invoiceable
    group_subscriptions = company.group_subscriptions_by_biller(custom_biller).where(user: user).invoiceable

    return nil unless reservations.length > 0 ||
                      game_passes.length > 0 ||
                      participations.length > 0 ||
                      group_subscriptions.length > 0

    invoice = self.create(
      company: company,
      owner: user,
      group_custom_biller: custom_biller,
      invoice_components: InvoiceComponent.build_from(reservations),
      gamepass_invoice_components: GamepassInvoiceComponent.build_from(game_passes),
      participation_invoice_components: ParticipationInvoiceComponent.build_from(participations),
      group_subscription_invoice_components: GroupSubscriptionInvoiceComponent.build_from(group_subscriptions),
    )
    invoice.add_default_fee!
    invoice.apply_credit_balance!

    invoice.reload
  end

  # from - to: optional dates
  def self.create_for_coach(coach, from: nil, to: nil)
    reservations =  coach.company.reservations.
                                  coach_owned.
                                  where(user_id: coach.id).
                                  invoiceable
    reservations =  reservations.between(from.beginning_of_day, to.end_of_day) if from && to

    return nil unless reservations.length > 0

    invoice = self.create(
      company: coach.company,
      owner: coach,
      invoice_components: InvoiceComponent.build_from(reservations),
    )
    invoice.add_default_fee!

    invoice.reload
  end

  def venue
    if invoice_components.first
      invoice_components.first.reservation.venue
    elsif gamepass_invoice_components.first
      gamepass_invoice_components.first.game_pass.venue
    elsif participation_invoice_components.first
      participation_invoice_components.first.participation.venue
    elsif group_subscription_invoice_components.first
      group_subscription_invoice_components.first.group_subscription.venue
    else
      nil
    end
  end

  def add_default_fee!
    return unless venue

    if venue.invoice_fee && venue.invoice_fee > 0
      custom_invoice_components.create!(
        name: I18n.t('helpers.label.venue.invoice_fee'),
        price: venue.invoice_fee,
        vat_decimal: BigDecimal.new('0.24'),
      )
      calculate_total!
    end
  end

  def apply_credit_balance!
    credit_amount = company.user_credit_balance(owner)
    credit_amount = total if total - credit_amount < 0

    unless credit_amount == 0
      apply_credit_amount!(credit_amount)
    end
  end

  # create custom invoice component with discount/addition
  # subtract/add credit balance and tie to custom invoice component
  def apply_credit_amount!(amount)
    type = amount < 0 ? 'addition' : 'discount'

    transaction do
      Credit.create!(
        user: owner,
        company: company,
        balance: amount * -1,
        creditable: custom_invoice_components.create!(
          name: I18n.t("invoices.custom_invoice_components.credit_#{type}"),
          price: amount * -1,
          vat_decimal: company.tax_rate
        )
      )
      calculate_total!
    end
  end

  def calculate_total
    items = all_items
    self.total = items.reject(&:marked_for_destruction?).sum(&:price)
  end

  def all_items
    invoice_components.to_a + gamepass_invoice_components.to_a + custom_invoice_components.to_a +
      participation_invoice_components.to_a + group_subscription_invoice_components.to_a
  end

  def calculate_total!
    calculate_total
    self.save! if total_changed?
  end

  def send!(custom_due_date = nil, from = nil)
    if custom_due_date.present?
      due_time = TimeSanitizer.input("#{custom_due_date} 00:00") rescue nil
    end

    transaction do
      invoice_components.includes(:reservation).map(&:bill!)
      gamepass_invoice_components.includes(:game_pass).map(&:bill!)
      participation_invoice_components.includes(:participation).map(&:bill!)
      group_subscription_invoice_components.includes(:group_subscription).map(&:bill!)
      custom_invoice_components.map(&:bill!)

      self.update_attributes(is_draft: false,
                             billing_time: Time.current.utc,
                             due_time: due_time)
      send_email(from)
    end
  end

  def undo_send!(from = nil)
    invoice_components.each(&:unbill!)
    gamepass_invoice_components.each(&:unbill!)
    participation_invoice_components.each(&:unbill!)
    group_subscription_invoice_components.each(&:unbill!)
    update_attributes(billing_time: nil,
                      due_time: nil,
                      is_draft: true)
    undo_send_email(from)
  end

  def send_email(from = nil)
    InvoiceMailer.invoice_email(self.owner, self, from).deliver_later!
  end

  def undo_send_email(from = nil)
    InvoiceMailer.undo_send_email(self.owner, self, from).deliver_later!
  end

  def charge!(token)
    self.transaction do
      Stripe::Charge.create(
        amount: self.total.to_int * 100,
        currency: 'usd',
        source: token,
        customer: self.owner.stripe_id,
        description: "#{self.company.company_legal_name} invoice #{self.id}",
        destination: self.company.stripe_user_id
      )
      self.invoice_components.map(&:charged!)
      self.gamepass_invoice_components.map(&:charged!)
      self.participation_invoice_components.map(&:charged!)
      self.group_subscription_invoice_components.map(&:charged!)
      self.custom_invoice_components.map(&:charged!)
      update(is_paid: true)
    end
  end

  def billing_date
    (billing_time&.in_time_zone || Time.current).to_date
  end

  def due_date
    due_time&.in_time_zone&.to_date || (billing_date + 2.weeks)
  end

  def due_days
    (due_date - billing_date).to_i
  end

  def mark_paid
    transaction do
      self.update_attribute(:is_paid, true)
      invoice_components.each(&:mark_paid!)
      gamepass_invoice_components.each(&:mark_paid!)
      participation_invoice_components.each(&:mark_paid!)
      group_subscription_invoice_components.each(&:mark_paid!)
      custom_invoice_components.each(&:mark_paid!)
    end
    true
  rescue StandardError => e
    p e.message
    false
  end

  def self.mark_paid(invoice_ids)
    invoices = Invoice.where(id: invoice_ids)
    count = 0

    invoices.each do |invoice|
      count += 1 if invoice.mark_paid
    end

    count
  end

  private

  def set_reference_number
    self.reference_number ||= FIViite.random(length: 10).paper_format
  end
end
