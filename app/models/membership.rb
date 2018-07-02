# Represents a user recurring membership
class Membership < ActiveRecord::Base
  include MembershipImportValidator
  include Recurrable
  include Sortable
  virtual_sorting_columns({
    customer_name: {
      joins: "LEFT OUTER JOIN users ON users.id = memberships.user_id AND memberships.user_type = 'User'",
      order: ->(direction) { "users.first_name #{direction}, users.last_name #{direction}" }
    },
    weekday: {
      joins: <<~SQL,
        left outer join reservations on reservations.id = (
          select reservations.id from reservations
            join membership_connectors on membership_connectors.reservation_id = reservations.id
            join memberships as tmp_memberships on membership_connectors.membership_id = tmp_memberships.id
            where tmp_memberships.id = memberships.id
            limit 1
        )
      SQL
      order: ->(direction) { "to_char(reservations.start_time, 'd') #{direction}" }
    },
    time: {
      # sorts GMT wise. Can mix +/- hour
      order: ->(direction) { "memberships.start_time::time #{direction}" }
    }
  })

  belongs_to :user, polymorphic: true
  belongs_to :venue
  has_one :company, through: :venue

  has_many :reservations, through: :membership_connectors, dependent: :destroy, autosave: true
  has_many :future_reservations, ->{ future }, through: :membership_connectors, source: :reservation
  # TODO: technically it should be through future_reservations, but then if reservation ends we
  # will always get an empty set
  has_many :courts, -> { distinct }, through: :reservations
  has_many :membership_connectors, dependent: :destroy
  has_many :activity_logs_payloads_connectors, as: :payload
  has_many :activity_logs, through: :activity_logs_payloads_connectors

  has_many :coach_connections, dependent: :destroy, class_name: 'Membership::CoachConnection'
  has_many :coaches, through: :coach_connections

  validates :venue, presence: true
  validates :user, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 },
                    allow_nil: false, presence: true
  validate :timing_order
  validate :max_duration, if: ['start_time?', 'end_time?']
  validate :ends_in_future, on: :create, unless: :importing?

  after_create :notify_membership_created
  after_update :notify_membership_updated

  # ignore_overlapping_reservations is a non persistent attribute
  attr_accessor :ignore_overlapping_reservations

  scope :search, ->(term) {
    # can't use joins(:user) because of polymorphic association
    joining { user.of(User).outer }.joining { user.of(Group).outer }.
    where(
      'users.first_name ilike :term OR users.last_name ilike :term OR groups.name ilike :term',
      term: "%#{term}%"
    )
  }

  # Memberships do not store courts directly (accessed through reservations)
  # We still want to track them, like they were on this model.
  # This may lead to cases when no reservations were updated (e.g. they were in past or already paid, hence not changed)
  # But since this is a virtual attribute it doesn't know what really happened, so courts changed would be logged,
  # even if in reality nothing was changed at all
  def assigned_court_ids
    @assigned_court_ids ||= court_ids
  end

  def assigned_court_ids=(ids)
    attribute_will_change! :assigned_court_ids if assigned_court_ids != ids
    @assigned_court_ids = ids
  end

  def reservations_weekday
    reservations.first&.start_time&.strftime('%A')&.downcase
  end

  def reservations_fingerprint
    sql = "md5(string_agg(reservations.updated_at::varchar, '' order by reservations.id)) as fingerprint"
    reservations.select(sql)[0][:fingerprint]
  end

  def for_group?
    user.is_a? Group
  end

  def group
    for_group? && user
  end

  private

  # validates if membership start_time is lesser than end_time
  def timing_order
    if start_time && end_time && end_time < start_time
      errors.add(:end_time, I18n.t('activerecord.errors.models.membership.attributes.end_time.timing_order'))
    end
  end

  # can only make maximum of two year reservations for one
  # membership
  def max_duration
    if start_time && end_time && (end_time - start_time) > 2.years
      errors.add :end_time, I18n.t('activerecord.errors.models.membership.attributes.end_time.max_duration_error')
    end
  end

  def ends_in_future
    if end_time&.past?
      errors.add :end_time, I18n.t('activerecord.errors.models.membership.attributes.end_time.in_the_past')
    end
  end

  def mailing_recipients
    if for_group?
      group.users
    else
      [user]
    end
  end

  def notify_membership_created
    return unless future_reservations.any?
    mailing_recipients.each do |recipient|
      MembershipMailer.membership_created(recipient, self).deliver_later
    end

    coaches.each do |coach|
      MembershipMailer.membership_created_for_coach(coach, self).deliver_later
    end
  end

  def notify_membership_updated
    return unless future_reservations.any?
    mailing_recipients.each do |recipient|
      MembershipMailer.membership_updated(recipient, self).deliver_later
    end

  end
end
