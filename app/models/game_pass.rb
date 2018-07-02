class GamePass < ActiveRecord::Base
  include TimeLimitations
  include CourtLimitations
  include Sortable
  virtual_sorting_columns({
    user_full_name: {
      joins: :user,
      order: ->(direction) { "users.first_name #{direction}, users.last_name #{direction}" }
    }
  })

  # TODO: NEVER use default_scope. We should get rid of it ASAP
  default_scope { where template_name: nil }

  enum billing_phase: [:not_billed, :drafted, :billed]

  belongs_to :user
  belongs_to :venue
  has_many :coach_connections, class_name: 'GamePass::CoachConnection', dependent: :destroy
  has_many :coaches, through: :coach_connections
  delegate :company, to: :venue, allow_nil: true

  validates :user_id, presence: true, unless: :template?
  validates :venue, presence: true

  before_save :mark_free_as_paid, unless: :is_paid?
  before_save :set_remaining_charges
  before_create :set_active

  scope :invoiceable, -> { not_billed.where(is_paid: false) }
  scope :templates, -> { unscope(where: :template_name).where.not(template_name: nil) }
  scope :not_templates, -> { where(template_name: nil) }
  scope :active, -> { where(active: true) }
  scope :has_charges, ->(charges) { where(arel_table[:remaining_charges].gteq(charges)) }
  scope :search, ->(term) do
    joins(:user).where('users.first_name ilike :term or users.last_name ilike :term', term: "%#{term}%")
  end
  scope :with_coaches, ->(coach_ids) do
    if coach_ids.any?
      # game passes without coach limitation or with matching coaches
      where('id IN (:with_matching_coaches) OR id IN (:for_any_coaches)',
        with_matching_coaches: with_coaches_matching(coach_ids).select(:id),
        for_any_coaches: for_any_coaches.select(:id))
    else
      # game passes without coach limitation
      for_any_coaches
    end
  end

  def self.with_coaches_matching(coach_ids)
    joins(:coach_connections).
      where(game_pass_coach_connections: { coach_id: coach_ids }).
      distinct.
      group("game_passes.id").
      having("COUNT(*) >= ?", coach_ids.length)
  end

  def self.for_any_coaches
    joining { [coach_connections.outer] }.
      where(game_pass_coach_connections: { id: nil })
  end

  def template?
    self.template_name.present?
  end

  def use_charges!(charges)
    update!(remaining_charges: remaining_charges - charges)
  end

  def restore_charges!(charges)
    update!(remaining_charges: remaining_charges + charges)
  end

  # for template return either name or template name, to use as template
  def name
    return self.template_name if self[:name].blank? && template?

    self[:name].to_s
  end

  # when at least some name is needed
  def auto_name
    charges = "#{remaining_charges}/#{total_charges}"

    return "#{charges} #{self.name}" if self.name.present?

    type  = Court.human_attribute_name("court_name.#{court_type}")

    "#{charges}|#{court_sports_to_s}|#{court_surfaces_to_s}|#{type}|#{dates_limit}|#{time_limitations_to_s}"
  end

  # returns user_id + lifetime values (as sum_price) for users in a whole company
  # useful for usage as a sub-query (e.g. in user sorting)
  def self.query_lifetime_values_by_user(company_id)
    selecting { [ user_id, price.sum.as('sum_price') ] }.
    joining { venue.outer }.
    where.has { venue.company_id == company_id }.
    grouping { user_id }
  end

  def self.query_outstanding_balances_by_user(company_id)
    not_billed_phase = GamePass.billing_phases[:not_billed]
    # outstanding balances is a subset of lifetime values, which are not yet paid
    query_lifetime_values_by_user(company_id).where.has do
      (is_paid == 'f') &
      (billing_phase == not_billed_phase)
    end
  end

  private

  def mark_free_as_paid
    self.is_paid = true if price == 0
  end

  def set_remaining_charges
    if remaining_charges.nil? || remaining_charges > total_charges
      self.remaining_charges = total_charges
    end
  end

  def set_active
    self.active = true if total_charges && total_charges > 0
  end
end
