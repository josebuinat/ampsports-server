class Company < ActiveRecord::Base
  include Settings
  has_settings :email_notifications, {
    reservation_created_for_owner: true,
    reservation_updated: true,
    participant_added_for_coach: true,
    participant_added_for_participant: true,
    participant_removed_for_coach: true,
    participant_removed_for_participant: true,
    coach_added: true,
    coach_removed: true,
    membership_created: true,
    membership_created_for_coach: true,
    membership_updated: true,
    admin_cancellation_email: true,
    added_to_the_group: true,
    removed_from_the_group: true,
    coach_added_to_the_group: true,
    coach_removed_from_the_group: true,
  }

  CURRENCY_UNITS = {
    'eur' => '€',
    'usd' => '$'
  }

  extend ActiveHash::Associations::ActiveRecordExtensions
  belongs_to_active_hash :country

  has_many :saved_invoice_user_connections
  has_many :saved_invoice_users, through: :saved_invoice_user_connections, source: :user
  has_many :admins, dependent: :destroy, class_name: '::Admin'
  has_one :god_admin, -> { god }, class_name: '::Admin'
  has_one :note
  has_many :coaches, dependent: :destroy, class_name: '::Coach'
  has_many :venues, dependent: :destroy
  has_many :memberships, through: :venues
  has_many :users, through: :venues
  has_many :reservations, through: :venues
  has_many :game_passes, through: :venues
  has_many :courts, through: :venues
  has_many :invoices, dependent: :destroy
  has_many :credits, dependent: :destroy
  has_many :activity_logs, dependent: :destroy
  has_many :groups, through: :venues
  has_many :group_reservations, through: :groups, source: :reservations
  has_many :group_seasons, through: :groups, source: :seasons
  has_many :group_subscriptions, through: :group_seasons
  has_many :group_custom_billers, -> { distinct }, through: :groups, source: :custom_biller
  has_many :participations, through: :reservations
  has_many :participation_credits, dependent: :destroy

  has_many :saved_invoice_user_connections,
    -> { where connection_type: SavedInvoiceUserConnection.connection_types[:saved] }
  has_many :recent_invoice_user_connections,
    -> { where connection_type: SavedInvoiceUserConnection.connection_types[:recent] },
    class_name: 'SavedInvoiceUserConnection'

  has_many :saved_invoice_users,
    through: :saved_invoice_user_connections,
    source: :user
  has_many :recent_invoice_users,
    through: :recent_invoice_user_connections,
    source: :user

  serialize :stripe_account_status, JSON

  validates :company_legal_name, presence: true
  validates :coupon_code, inclusion: { in: proc { Coupon.pluck(:code) } },
    allow_blank: true, on: :create

  # Stripe::BalanceTransaction.all({:transfer => "tr_17yKSgBavI8QpPIoLEJe4Zut"}, {:stripe_account => self.stripe_user_id})

  # reservations for users including owned groups reservations
  # can take array of users
  def user_reservations(user)
    reservations.users_with_groups(user).order(created_at: :asc)
  end

  # return memberships owners: either direct user, or group owner user
  def memberships_users
    group_ids_select = memberships.select(:user_id).where(user_type: 'Group')

    User.where('id IN (:user_ids) OR id IN (:group_owner_ids)',
                user_ids: memberships.select(:user_id).where(user_type: 'User'),
                group_owner_ids: Group.where(id: group_ids_select).select(:owner_id))
  end

  # means they decide whether company can go public or not
  def stripe_sensetive_fields
    %i(country_id company_tax_id company_business_type company_street_address
      company_zip company_city bank_name company_bic company_iban)
  end

  def can_be_listed_as_public?
    stripe_sensetive_fields.all? { |field| public_send(field).present? } &&
      god_admin.has_ssn? && god_admin.birth_date.present?
  end

  def connected?
    !stripe_user_id.nil?
  end

  def has_stripe?
    stripe_user_id != nil
  end

  def managed?
    stripe_account_type == 'managed'
  end

  def can_accept_charges
    managed? && stripe_account_status['charges_enabled']
  end

  def transfers(start_date, end_date)
    Stripe::Transfer.all(
      {
        date: {
          gte: (DateTime.parse(start_date)).to_i,
          lte: (DateTime.parse(end_date)).to_i
        }
      },
      { stripe_account: self.stripe_user_id }
    )
  end

  def transfer_transactions(transfer)
    Stripe::BalanceTransaction.all({ transfer: transfer }, { stripe_account: self.stripe_user_id })
  end

  def trans_hist(grouping)
    Stripe::BalanceTransaction.all(self.filter(grouping), { stripe_account: self.stripe_user_id })
  end

  def balance
    Stripe::Balance.retrieve({ stripe_account: self.stripe_user_id }).pending[0].amount / 100
  end

  def charges_data(grouping)
    data = self.charges(grouping)
    amount = 0
    data.each do |d|
      amount += d.amount
    end

    {
      count: data.count,
      amount: amount / 100
    }
  end

  def charges(grouping)
    Stripe::Charge.all(
      self.filter(grouping),
      { stripe_account: self.stripe_user_id }
    ).data
  end

  def customers
    customers = []
    User.all.each do |user|
      companies = user.reservations.map do |reservation|
        reservation.court.venue.company
      end
      customers << user if companies.include? self
    end
    return customers
  end

  def user_credit_balance(user)
    credits.where(user: user).sum(:balance)
  end

  def credit_balances
    balances = credits.group(:user_id).sum(:balance)

    users.map { |user| [user.id, (balances[user.id] || 0).to_d] }.to_h
  end

  # query participations by biller, or without biller(if nil)
  def participations_by_biller(group_custom_biller)
    participations.where(reservation_id: reservations.groups(groups.custom_biller(group_custom_biller)))
  end
  # query group subscriptions by biller, or without biller(if nil)
  def group_subscriptions_by_biller(group_custom_biller)
    group_subscriptions.where(group_season_id: group_seasons.groups(groups.custom_biller(group_custom_biller)))
  end

  def coach_outstanding_balance(coach)
    reservations.coach_owned.
                  where(user_id: coach.id).
                  invoiceable.
                  map { |r| r.outstanding_balance || 0.to_d }.sum.to_d
  end

  def coach_outstanding_balances
    invoiceable_reservations = reservations.coach_owned.
                                            invoiceable.
                                            group_by(&:user_id)

    coaches.pluck(:id).map do |coach_id|
      [coach_id,
        invoiceable_reservations[coach_id].to_a.
          map { |r| r.outstanding_balance || 0.to_d }.sum.to_d
      ]
    end.to_h
  end

  # calculates unpaid and not invoiced amount for user for current company
  def user_outstanding_balance(user, group_custom_biller = nil)
    if group_custom_biller.present?
      # only participations and subscriptions for biller
      invoiceable_reservations = invoiceable_game_passes = []
    else
      invoiceable_reservations = user_reservations(user).invoiceable
      invoiceable_game_passes = game_passes.where(user: user).invoiceable
    end

    invoiceable_participations = participations_by_biller(group_custom_biller).
                                   where(user: user).invoiceable
    invoiceable_group_subscriptions = group_subscriptions_by_biller(group_custom_biller).
                                        where(user: user).invoiceable

    invoiceable_reservations.map { |r| r.outstanding_balance || 0.to_d }.sum.to_d +
      invoiceable_game_passes.map { |r| r.price || 0.to_d }.sum.to_d +
      invoiceable_participations.map { |r| r.price || 0.to_d }.sum.to_d +
      invoiceable_group_subscriptions.map { |r| r.price || 0.to_d }.sum.to_d
  end

  # calculates unpaid and not invoiced amounts for all users for current company
  def outstanding_balances(group_custom_biller = nil)
    if group_custom_biller.present?
      # only participations and subscriptions for biller
      invoiceable_reservations = invoiceable_game_passes = []
    else
      invoiceable_reservations = reservations.invoiceable.
                                              users_with_groups(users).
                                              includes(:user).
                                              group_by(&:fetch_owner_id)
      invoiceable_game_passes = game_passes.invoiceable.group_by(&:user_id)
    end

    invoiceable_participations = participations_by_biller(group_custom_biller).
                                   invoiceable.group_by(&:user_id)
    invoiceable_group_subscriptions = group_subscriptions_by_biller(group_custom_biller).
                                        invoiceable.group_by(&:user_id)

    users.map do |user|
      [user.id,
        invoiceable_reservations[user.id].to_a.map { |r| r.outstanding_balance || 0.to_d }.sum.to_d +
        invoiceable_game_passes[user.id].to_a.map { |r| r.price || 0.to_d }.sum.to_d +
        invoiceable_participations[user.id].to_a.map { |r| r.price || 0.to_d }.sum.to_d +
        invoiceable_group_subscriptions[user.id].to_a.map { |r| r.price || 0.to_d }.sum.to_d
      ]
    end.to_h
  end

  # calculates paid amount for user for current company
  def user_lifetime_balance(user)
    reservations_balance = user_reservations(user).sum(:price)
    game_passes_balance = game_passes.where(user: user).sum(:price)
    participations_balance = participations.where(user: user).sum(:price)
    group_subscriptions_balance = group_subscriptions.where(user: user).sum(:price)

    reservations_balance.to_d +
      game_passes_balance.to_d +
      participations_balance.to_d +
      group_subscriptions_balance.to_d
  end

  # calculates paid amounts for all users for current company
  def lifetime_balances(user_ids = nil)
    reservations_relation = reservations.includes(:user)
    game_passes_relation = game_passes
    participations_relation = participations
    group_subscriptions_relation = group_subscriptions

    if user_ids.present?
      game_passes_relation.where!(user_id: user_ids)
      participations_relation.where!(user_id: user_ids)
      group_subscriptions_relation.where!(user_id: user_ids)
      # cannot do this on reservations because they may belong to a group, where we have to bill
      # the owner of that group (that's why we group on `fetch_owner_id`)
      # reservations_relation.where!(user_id: user_ids)
    end

    reservations_by_user = reservations_relation.group_by(&:fetch_owner_id)
    game_passes_balances  = game_passes_relation.group(:user_id).sum(:price)
    participations_balances  = participations_relation.group('participations.user_id').sum(:price)
    group_subscriptions_balances  = group_subscriptions_relation.group(:user_id).sum(:price)

    users.map do |user|
      [user.id,
        (reservations_by_user[user.id].to_a.map(&:price).sum || 0).to_d +
          (game_passes_balances[user.id] || 0).to_d +
          (participations_balances[user.id] || 0).to_d +
          (group_subscriptions_balances[user.id] || 0).to_d
      ]
    end.to_h
  end

  def filter(grouping)
    case
    when grouping == 'day'
      {
        created: {
          gte: Time.now.beginning_of_day.to_i,
          lt: Date.tomorrow.beginning_of_day.to_i
        }
      }
    when grouping == 'month'
      {
        created: {
          gte: Time.now.beginning_of_month.to_i,
          lt: Time.now.beginning_of_month.next_month.to_i
        }
      }
    when grouping == 'year'
      {
        created: {
          gte: Time.now.beginning_of_year.to_i,
          lt: Time.now.beginning_of_year.next_year.to_i
        }
      }
    end
  end

  def last_god?(admin)
    !admins.any? { |other_admin| other_admin != admin && other_admin.role?('god') }
  end

  def currency_unit
    # fallback to dollar
    CURRENCY_UNITS[currency] || '$'
  end

  def invoice_sender_email
    self[:invoice_sender_email].present? ? self[:invoice_sender_email] : 'no-reply@playven.com'
  end

  # return VAT decimal based on company_business_type
  # decimal = percentage / 100
  # TODO use enum for company_business_type
  def get_vat_decimal
    case company_business_type
    when 'Rekisteröity yhdistys'
      BigDecimal.new('0')
    else
      BigDecimal.new('0.10')   # 10 %
    end
  end

  def tax_name
    key = country_id == 2 ? 'sales_tax' : 'vat'
    I18n.t("companies.taxes.#{key}")
  end

  def save_invoice_users(invoiced_users)
    invoiced_users.map do |user|
      self.saved_invoice_user_connections.find_or_create_by(user: user)
    end
  end

  def save_with_stripe(admin, remote_ip)
    transaction do
      return false unless save
      admin.update_attribute(:company_id, id)
      admin.company = self
      StripeManaged.new(self).create_account!(admin, true, remote_ip)
      true
    end
  rescue Stripe::StripeError => e
    errors.add(:stripe, I18n.t('errors.company.stripe'))
    errors.add(:stripe, e.message)
    false
  end
end
