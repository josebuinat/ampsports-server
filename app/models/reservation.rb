# Represents a user continous reservation of a court
# for a certain amount of time
class Reservation < ActiveRecord::Base
  include ReservationValidator
  include ReservationResellable
  include ReservationParticipations
  include ReservationLogging
  include ReservationMailable
  include Cancelable
  include Taxable
  include TimeSpreadable

  class ChargeParamsError < StandardError; end

  default_scope { where inactive: false }

  attr_accessor :recalculate_price_on_save

  belongs_to :court
  belongs_to :classification, class_name: 'GroupClassification'
  has_one :venue, through: :court
  has_one :company, through: :venue
  # main owner
  belongs_to :user, polymorphic: true
  # other players (participants)
  has_many :participant_connections, inverse_of: :reservation, dependent: :destroy
  has_many :participants, class_name: 'User', through: :participant_connections, source: :user
  belongs_to :game_pass
  has_many :coach_connections, class_name: 'Reservation::CoachConnection',
    dependent: :destroy, inverse_of: :reservation
  # Important: dependent: :destroy on `coaches` here WILL NOT REMOVE COACHES. We have a test to ensure that.
  # We need that to make coach_connections run destroy callbacks when we do `reservation.coach_ids = [new_id]`
  has_many :coaches, through: :coach_connections, dependent: :destroy
  has_many :invoice_components, dependent: :destroy
  has_one :membership_connector, dependent: :destroy
  has_one :membership, through: :membership_connector
  has_one :venue, through: :court
  has_one :company, through: :venue
  has_many :logs, class_name: 'ReservationsLog', inverse_of: :reservation, foreign_key: :reservation_id, dependent: :destroy
  has_many :activity_logs_payloads_connectors, as: :payload
  has_many :activity_logs, through: :activity_logs_payloads_connectors

  accepts_nested_attributes_for :participant_connections, allow_destroy: true

  scope :cancelled, -> { unscope(where: :inactive).where(inactive: true) }
  scope :past, -> { where('start_time < ?', Time.current) }
  scope :future, -> { where('start_time > ?', Time.current) }
  scope :recurring, -> { joins(:membership_connector) }
  scope :non_recurring, -> { joining { [membership_connector.outer] }.where(membership_connectors: { id: nil }) }
  scope :non_coached, -> { joining { [coach_connections.outer] }.where.has { coach_connections.id == nil } }
  scope :include_venues, -> { includes(court: { venue: :photos }) }
  scope :invoiceable, -> { not_billed.where(is_paid: false, payment_type: [1, 2]) } # payment_type: unpaid, semi_paid
  scope :between, ->(from, to) { where(arel_table[:start_time].gteq(from).and(arel_table[:end_time].lteq(to))) }
  scope :for_company, ->(company) { joins(court: { venue: :company }).where(companies: { id: company.id }) }
  scope :for_venue, ->(venue) { joins(court: :venue).where(venues: { id: venue.id }) }
  scope :for_sport, ->(sport) { joins(:court).where(courts: { sport_name: Court.sport_names[sport] }) }
  scope :for_user, ->(user_id) do # only for 'User' user_type
    # include reservations where user is one of participants or one of group-participants
    joining { [participant_connections.outer, participations.outer] }.
    where.has { |r| (r.user_id == user_id) & (r.user_type == 'User') |
      (r.participant_connections.user_id == user_id) & (r.user_type.in ['User', 'Coach']) |
      (r.participations.user_id == user_id) & (r.participations.cancelled == false) & (r.user_type == 'Group')
    }.distinct
  end
  scope :for_coach, ->(coach_id) do
    # owned or coached by coach
    joining { [coach_connections.outer] }.
    where.has { |r| (r.user_id == coach_id) & (r.user_type == 'Coach') |
      (r.coach_connections.coach_id == coach_id)
    }.distinct
  end
  scope :coach_owned, -> { where(user_type: 'Coach') }

  enum booking_type: [:online, :admin, :membership, :guest]
  enum payment_type: [:paid, :unpaid, :semi_paid]
  enum billing_phase: [:not_billed, :drafted, :billed]

  before_validation :assign_coaches, if: :new_record?
  before_save  :set_payment_type, unless: 'paid?'
  before_save  :recalculate_price!, if: :recalculate_price_on_save
  after_save   :pay_with_game_pass, if: :should_pay_with_game_pass?
  after_save   :delete_invoice_components, if: :was_cancelled?
  after_save   :cancel_overlapping_reservations # for venues which allows that
  # first participant = owner
  after_create :create_first_participant_from_owner

  def self.on_date(date)
    t = arel_table
    start_time = TimeSanitizer.output(date).at_beginning_of_day
    end_time   = TimeSanitizer.output(date).at_end_of_day + 1.second

    where t[:start_time].gteq(start_time).and(t[:end_time].lteq(end_time))
  end

  def self.for_person(id, type)
    case type
    when 'User'
      for_user(id)
    when 'Coach'
      for_coach(id)
    else
      where(user_id: id, user_type: type)
    end
  end

  def track_booking
    if online?
      user_payment_type = charge_id.present? ? "User with Card" : "User with Game Pass"
      SegmentAnalytics.booking(court.venue, self, user, user_payment_type) if paid?
      SegmentAnalytics.unpaid_booking(court.venue, self, user) if unpaid?
    elsif admin?
      SegmentAnalytics.booking(court.venue, self, user, 'Admin') if paid?
      SegmentAnalytics.unpaid_booking(court.venue, self, user, 'Admin') if unpaid?
    end
  end

  def get_overlapping_reservations
    court_ids = CourtConnector.where(court_id: court_id).pluck(:shared_court_id) << court_id

    Reservation.joins(:venue).where(court_id: court_ids).where.not(id: id).
      where('reservations.reselling = false OR venues.allow_overlapping_resell = false').
      overlapping(start_time, end_time)
  end

  def overlapping_reservations_with_partial_resell
    court_ids = CourtConnector.where(court_id: court_id).pluck(:shared_court_id) << court_id

    Reservation.joins(:venue).where(court_id: court_ids).where.not(id: id).
      where('reservations.reselling = true AND venues.allow_overlapping_resell = true').
      overlapping(start_time, end_time)
  end

  def conflicting?(starts, ends)
    return false if can_be_resold?(starts, ends)

    overlapping?(starts, ends)
  end

  def overlapping?(starts, ends)
    (start_time >= starts && start_time < ends)  ||
      (end_time > starts && end_time <= ends)    ||
      (start_time <= starts && end_time >= ends)
  end

  def can_be_resold?(starts, ends)
    reselling? &&
      (venue.allow_overlapping_resell || # any overlapping
      (start_time == starts && end_time == ends)) # only exactly matching
  end

  def recurring?
    membership.present?
  end

  def future?
    start_time > Time.current.utc
  end

  def guest_user?
    user_type == 'Guest'
  end

  def for_coach?
    user.is_a? Coach
  end

  def to_ics
    # !! this info can be accessed by anyone through api_reservation_download_url
    # update controller if you want to add email/name or other confidential info
    venue = court.venue
    event = Icalendar::Event.new
    event.dtstart = TimeSanitizer.output(start_time)
    event.dtend = TimeSanitizer.output(end_time)
    event.summary = court.sport_name + ' at ' + venue.venue_name
    event.description = court.sport_name
    event.location = [venue.street, venue.zip, venue.city].join(' ')
    event.created = created_at
    event.last_modified = updated_at
    event
  end

  # try to pay with card or mark as unpaid
  # should be used only for saved reservation
  # returns true on success
  def charge(token)
    stripe_charge_params = charge_params(token)

    charge = Stripe::Charge.create(stripe_charge_params)
    update_attributes(is_paid: true,
                      payment_type: :paid,
                      amount_paid: price,
                      charge_id: charge.id)
  rescue Stripe::StripeError, ChargeParamsError => e
    update_attributes(billing_phase: :not_billed,
                      is_paid: false,
                      payment_type: :unpaid)

    errors.add :payment, I18n.t('errors.reservation.card_payment_error')

    Rollbar.error(e, 'Stripe charge failed', reservation_id: id,
                                             charge_params: stripe_charge_params)
    false
  end

  # returns true on success
  def pay_with(card_token: nil, game_pass_id: nil)
    if card_token.present?
      charge(card_token)
    elsif game_pass_id.present?
      update(game_pass_id: game_pass_id) # will try to use game pass in the callback
    else
      errors.add :payment, I18n.t('errors.reservation.unknown_payment_method')
      false
    end
  end

  # duration in minutes
  def duration
    TimeSanitizer.duration(start_time, end_time).to_f / 60
  end

  def hours
    duration / 60
  end

  def paid_in_full=(value)
    if value
      self.amount_paid = price
      self.payment_type = :paid
    end
    value
  end

  def paid_in_full
    return true if paid?
    amount_paid.to_f >= price.to_f
  end

  def coach_salary(coach)
    connection = find_coach_connection(coach)
    connection ? connection.salary : 0.to_d
  end

  def coach_salary_paid(coach)
    find_coach_connection(coach)&.salary_paid
  end

  def mark_coach_salary_paid(coach)
    !!find_coach_connection(coach)&.mark_salary_paid
  end

  # use preloaded connections if possible
  def find_coach_connection(coach)
    if coach_connections.loaded?
      coach_connections.to_a.find { |connection| connection.coach_id == coach.id }
    else
      coach_connections.find_by(coach_id: coach.id)
    end
  end

  # TODO(aytigra): delete owerride after data mingration
  #                when this fields will be removed from schema
  def as_json(options={})
    super(except: [:coach_id, :coach_salary, :coach_salary_paid])
  end

  def game_pass_available?(game_pass)
    user.available_game_passes(court, start_time, end_time, coach_ids).include?(game_pass)
  end

  def name
    Time.use_zone(venue&.timezone || Time.zone) do
      "#{court.sport} " +
        "#{TimeSanitizer.strftime(start_time, :date)}, " +
        "#{TimeSanitizer.strftime(start_time, :time)} - " +
        "#{TimeSanitizer.strftime(end_time, :time)}, " +
        "#{court.court_name}"
    end
  end

  def description
    unit = company.currency_unit # $ / €
    "#Reservation: #{court.court_name} at #{court.venue.venue_name} for #{unit}#{price}"
  end

  def set_payment_type
    self.amount_paid ||= 0
    self.payment_type = if amount_paid >= price
                          :paid
                        elsif amount_paid > 0
                          :semi_paid
                        else
                          :unpaid
                        end
  end

  def color
    color = venue&.get_user_color(user)
    return color if color.present?

    colors = venue&.custom_colors || Venue::DEFAULT_COLORS

    if coaches.any?
      candidate_color = coaches.map { |coach| venue.get_coach_color(coach.id) }.compact.first

      return candidate_color if candidate_color.present?
      return colors[:coached] if colors[:coached].present?
    end

    group_or_reservation_classification_id = for_group? ? group.classification_id : classification_id

    if group_or_reservation_classification_id.present?
      # classification color take precedence over group own color
      candidate_color = venue.get_classification_color(group_or_reservation_classification_id)
      return candidate_color if candidate_color.present?
    end

    if for_group?
      candidate_color = venue.get_group_color(group.id)
      return candidate_color if candidate_color.present?
    end

    if online? && colors[:online_booking]
      colors[:online_booking]
    elsif reselling? && colors[:reselling]
      colors[:reselling]
    elsif membership?
      if (paid? || billed?) && colors[:membership_paid]
        return colors[:membership_paid]
      elsif semi_paid? && colors[:membership_semi_paid]
        return colors[:membership_semi_paid]
      elsif colors[:membership_unpaid]
        return colors[:membership_unpaid]
      end
      return colors[:other]
    elsif billed? && !paid? && colors[:invoiced]
      colors[:invoiced]
    elsif paid? || billed?
      guest_user? ? (colors[:guest_paid] || colors[:paid]) : colors[:paid]
    elsif unpaid?
      guest_user? ? (colors[:guest_unpaid] || colors[:unpaid]) : colors[:unpaid]
    elsif semi_paid?
      guest_user? ? (colors[:guest_semi_paid] || colors[:semi_paid]) : colors[:semi_paid]
    else
      colors[:other]
    end
  end

  # returns non nil outstanding balance
  def outstanding_balance
    paid? ? 0.to_d : price - (amount_paid || 0.to_d)
  end

  # returns non nil amount_paid
  def get_amount_paid
    paid? ? price : (amount_paid || 0.to_d)
  end

  def get_payment_method
    if paid?
      charge_id.present? ? I18n.t('reservations.online') : I18n.t('reservations.at_venue')
    elsif billed?
      I18n.t('reservations.invoiced')
    else
      I18n.t('reservations.unpaid')
    end
  end

  # returns reservation event json for full calendar
  def as_json_for_calendar(venue_id)
    calendar_json = {
      id: id,
      user_id: user_id,
      user_type: user_type,
      owner_phone: owner_phone_number,
      start: TimeSanitizer.output(start_time),
      end: TimeSanitizer.output(end_time),
      price: price,
      amount_paid: amount_paid,
      title: reservation_title,
      resourceId: court_id,
      color: color,
      url: "/venues/#{venue_id}/reservations/#{id}",
      note: note,
      reselling: reselling,
      coach_name: coaches.map(&:first_name).join(', '),
      recurring: recurring?,
    }

    if for_group?
      calendar_json.merge({
        group_name: group.name,
        participations_count: participations_count,
        max_participations: group.max_participants,
      })
    else
      calendar_json
    end
  end

  def reservation_title
    if for_group?
      group.name
    elsif membership&.title&.present?
      membership&.title
    else
      user&.full_name
    end
  end

  def owner_phone_number
    if for_group?
      group.admin_owned? ? venue.phone_number : group.owner.phone_number
    else
      user.try(:phone_number)
    end
  end

  def owner_name
    if for_group?
      group.owner_name
    else
      user.full_name
    end
  end

  def price_for(customer)
    if for_group? && customer != group.owner
      participation_for(customer)&.price || group.participation_price
    else
      price
    end
  end

  # used mostly when rendering a big reservation lists
  # we assume participations should be preloaded
  def participation_for(customer)
    participations.find { |p| !p.cancelled? && p.user_id == customer.id }
  end

  def self.reservations_for_memberships(membership_ids)
    select = 'reservations.*, membership_connectors.membership_id as membershipid'
    @reservations = Reservation.joins(:membership_connector).
                                select(select).
                                where(membership_connectors: { membership_id: membership_ids }).
                                includes(:court).
                                group_by(&:membershipid)
  end

  def logged_courts
    courts_ids = logs.map { |log_entry| log_entry.params[:court_id] }
    Court.where(id: courts_ids.compact.uniq)
  end

  # legacy method, used in old ReservationController#update. Should be deleted when new admin kicks in
  def recalculate_price_and_update!
    update(price: calculate_price)
  end

  def recalculate_price!
    self.price = calculate_price
  end

  def calculate_price
    return nil if court.nil?

    if classification_id.present? && user_type != 'Group'
      classification = venue.group_classifications.find(classification_id)

      # classification.price can be nil (created before that field was added)
      # calculate the price only if we can do that, otherwise fall through reservation based calculations
      if classification.price_can_be_calculated?
        return classification.price_at(start_time, end_time)
      end
    end

    if user_type != 'Coach' && coach_ids.any?
      # use venue.company to avoid joining with in-memory model
      coaches = venue.company.coaches.where(id: coach_ids)
      return coaches.to_a.sum { |coach| coach.price_at(start_time, end_time, court) }
    end

    # user_type.nil? is a fallback for the older code, allowed any type (e.g. Guest, by mistake) to use a discount
    discount = if user_id.present? && (user_type == 'User' || user_type.nil?)
      user = venue.users.find_by(id: user_id)
      user && user.discount_for(court, start_time, end_time)
    else
      nil
    end
    court.price_at(start_time, end_time, discount)

    # discount = user.is_a?(User) ? user.discounts.where(venue: court.venue).first : nil
    # court.price_at(start_time, end_time, discount)
  end

  # returns user_id + lifetime values (as sum_price) for users in a whole company
  # useful for usage as a sub-query (e.g. in user sorting)
  def self.query_lifetime_values_by_user(company_id)
    selecting { [ user_id, price.sum.as('sum_price') ] }.
    joining { court.outer.venue.outer }.
    where.has { court.venue.company_id == company_id }.
    grouping { user_id }
  end

  def self.query_outstanding_balances_by_user(company_id)
    not_completely_paid = [Reservation.payment_types[:unpaid], Reservation.payment_types[:semi_paid]]
    not_billed_phase = Reservation.billing_phases[:not_billed]
    # outstanding balances is a subset of lifetime values, which are not yet paid
    # As a future improvment price can be selected as follows:
    # paid? ? 0.to_d : price - (amount_paid || 0.to_d)
    query_lifetime_values_by_user(company_id).where.has do
      (is_paid == 'f') &
      (inactive == 'f') &
      (billing_phase == not_billed_phase) &
      (payment_type.in not_completely_paid)
    end
  end

  def convenience_fee
    court.convenience_fee(price)
  end

  def price_with_convenience_fee
    price + court.convenience_fee(price)
  end

  def calculate_tax_with_convenience_fee
    price_with_convenience_fee - calculate_price_with_convenience_fee_without_tax
  end

  def calculate_price_with_convenience_fee_without_tax
    ((price_with_convenience_fee / (1 + tax_rate)) * 100).ceil.to_f / 100
  end

  def amount_paid=(value)
    assign_correct_payment_type value, price
    super
  end

  def price=(value)
    assign_correct_payment_type amount_paid, value
    super
  end

  private

  def create_first_participant_from_owner
    return unless user.is_a?(User)
    participant_connections.create amount_paid: 0, price: price, user_id: user_id, skip_association_with_venue: true
  end

  def assign_correct_payment_type(amount_paid, price)
    # sometimes (at least in tests) these values can be non-numerical
    amount_paid = amount_paid.to_f
    price = price.to_f

    self.payment_type = if amount_paid >= price
      :paid
    elsif amount_paid > 0
      :semi_paid
    else
      :unpaid
    end

    self.is_paid = payment_type == 'paid'
  end

  def charge_params(token)
    total_amount = price || 0

    if court.country.US?
      # convenience fee on top, take from user
      total_amount = total_amount + court.calculate_stripe_fee(total_amount)
      # 0.5% US platform fee, take from user
      total_amount = total_amount * 1.005
      # 1$ US platform fee, take from venue
      venue_amount = total_amount - 1
    else
      # Stripe fee, take from venue
      venue_amount = total_amount - court.calculate_stripe_fee(total_amount)
      # 0.5% platform fee, take from venue
      venue_amount = venue_amount * (1 - 0.005)
    end

    if venue_amount < 0
      raise ChargeParamsError, I18n.t('errors.stripe.negative_amount',
                                        amount: total_amount,
                                        venue_amount: venue_amount)
    end

    {
      amount: (total_amount * 100).ceil,
      currency: company.currency.presence || 'eur',
      source: token,
      customer: user.stripe_id,
      description: description,
      destination: {
        account: company.stripe_user_id,
        amount: (venue_amount * 100).ceil
      }
    }
  end

  def was_cancelled?
    inactive_changed? && inactive?
  end

  def delete_invoice_components
    invoices = invoice_components.map(&:invoice)

    InvoiceComponent.without_undraft_callback do
      invoice_components.destroy_all
    end

    invoices.each(&:calculate_total!)
  end

  def cancel_overlapping_reservations
    overlapping_reservations_with_partial_resell.each do |reservation|
      reservation.cancel(self, false)
    end
  end

  def should_pay_with_game_pass?
    # either not yet paid, either paid, but just changed to that type
    # paid? will be automatically set in `set_payment_type` callback
    not_yet_paid = !paid? || payment_type_changed?
    not_yet_paid && game_pass_id_changed? && game_pass_id.present?
  end

  # use game pass and mark self as paid
  # fail save if can't use new game_pass_id
  def pay_with_game_pass
    if game_pass.blank?
      errors.add(:game_pass, I18n.t('errors.reservation.game_pass.not_found'))
      raise ActiveRecord::RecordInvalid.new(self)
    end

    if game_pass_available?(game_pass)
      game_pass.use_charges!(hours)
      # Callback hell: update_attributes calls new before_save callbacks, which again check whether
      # we are able to pay with the pass (and we are) and pay it again, until game_pass if fully drained.
      # Have to reset game_pass_id_changed? to false BEFORE updating the attributes again
      clear_changes_information
      update_attributes(is_paid: true, payment_type: :paid, amount_paid: price)
    else
      errors.add(:game_pass, I18n.t('errors.reservation.game_pass.not_available'))
      raise ActiveRecord::RecordInvalid.new(self)
    end
  end

  def assign_coaches
    if for_group?
      group.coaches.each do |coach|
        if coach.available?(court, start_time, end_time, id)
          self.coach_connections.build(coach: coach) unless coaches.include?(coach)
        end
      end
    elsif for_coach? && !coaches.include?(user)
      self.coach_connections.build(coach: user)
    end
  end
end
