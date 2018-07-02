# represents a venue group description
class Group < ActiveRecord::Base
  include Sortable

  serialize :skill_levels, Array

  SKILL_LEVELS = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0].freeze

  belongs_to :venue
  belongs_to :owner, polymorphic: true
  belongs_to :classification, class_name: 'GroupClassification'
  has_many :coach_connections, class_name: 'Group::CoachConnection', dependent: :destroy
  # Important: dependent: :destroy on `coaches` here WILL NOT REMOVE COACHES. We have a test to ensure that.
  # We need that to make coach_connections run destroy callbacks when we do `group.coach_ids = [new_id]`
  has_many :coaches, through: :coach_connections, dependent: :destroy
  belongs_to :custom_biller, class_name: 'GroupCustomBiller'
  has_many :reservations, as: :user, dependent: :destroy
  has_many :memberships, dependent: :destroy, as: :user
  # "members" is kind a bad name, better go with Group::Membership
  has_many :members, class_name: 'GroupMember', dependent: :destroy
  has_many :users, through: :members
  has_many :seasons, class_name: 'GroupSeason', dependent: :destroy
  has_many :subscriptions, through: :seasons, source: :group_subscriptions
  has_one :company, through: :venue
  delegate :email, :full_name, :locale, :time_format, :clock_type, to: :owner

  enum priced_duration: [:session, :hour, :season]
  enum cancellation_policy: [:participation, :refund, :no_refund]

  validates :venue, :owner, :classification, :name, :skill_levels,
            :participation_price, :max_participants, presence: true
  validates :max_participants, numericality: { only_integer: true }

  after_destroy :delete_custom_biller_without_groups

  scope :custom_biller, ->(custom_biller) { where(custom_biller_id: custom_biller&.id) }
  scope :search, ->(term) { where('name ilike :term', term: "%#{term}%") }
  scope :base_includes, -> do
    includes(:owner, :coaches, :classification, :seasons)
  end
  scope :for_user, ->(user) do
    joining { [members.outer] }.
    where.has {
      (members.user_id == user.id) | (owner_id == user.id) & (owner_type == 'User')
    }.distinct
  end
  scope :for_coach, ->(coach) do
    where(id: Group::CoachConnection.where(coach: coach).select(:group_id))
  end

  scope :accepts_classification, ->(classification) { where(classification: classification) }

  def self.accepts_skill_level(skill_level)
    if SKILL_LEVELS.include?(skill_level.to_f)
      where("skill_levels like '% :level\n%'", level: skill_level.to_f)
    else
      all
    end
  end

  def skill_levels=(raw_levels)
    self[:skill_levels] = raw_levels.to_a.map(&:to_f) & SKILL_LEVELS
  end

  def skill_levels
    self[:skill_levels] || []
  end

  def admin_owned?
    owner.is_a?(Admin)
  end

  def name_with_details
    <<-NAME
      #{name}
      , #{participation_price}(#{priced_duration})
      , #{owner.full_name}#{admin_owned? ? "(#{I18n.t('admin')})" : ''}
    NAME
  end

  def current_season
    seasons.current.first
  end

  def seasons_covering(start_time, end_time)
    Time.use_zone(venue.timezone) do
      seasons.covering(start_time.in_time_zone.to_date, end_time.in_time_zone.to_date)
    end
  end

  def update_with_seasons(group_params, seasons_params)
    transaction do
      update!(group_params)

      seasons_params.each do |season_params|
        season = find_or_build_season(season_params.except(:_destroy))

        if season.id && season_params[:_destroy]
          season.destroy!
          next
        end

        unless season.save
          # nested attributes add errors within dot notation, e.g.
          # { errors: { sessions.start_time: ['cannot be blank'] } }
          # since we mimic nested attributes we have to maintain same style of errors
          season.errors.messages.each_pair do |error, value|
            self.errors.add "seasons.#{error}", *value
          end
          raise ActiveRecord::RecordInvalid.new(self)
        end
      end
      shift_current_season
    end
    true
  rescue ActiveRecord::RecordInvalid,
            ActiveRecord::RecordNotSaved,
            ActiveRecord::RecordNotDestroyed
    false
  end

  def find_or_build_season(params)
    if params[:id] && season = seasons.find_by_id(params[:id])
      season.assign_attributes(params)
    else
      season = seasons.build(params)
    end

    season
  end

  def owner_name
    if admin_owned?
      venue.venue_name
    else
      owner.full_name
    end
  end

  # in case current season was destroyed
  def shift_current_season
    if seasons.current.none? && seasons.any?
      seasons.last.update_attribute(:current, true)
    end
  end

  def create_duplicate
    venue.groups.create(
      seasons: seasons.map(&:build_duplicate),
      **[:owner, :classification_id, :coach_ids, :name, :description, :participation_price,
         :max_participants, :priced_duration, :cancellation_policy, :skill_levels].
            map { |attr| [attr, public_send(attr)] }.to_h
    )
  end

  private

  def delete_custom_biller_without_groups
    if custom_biller.present? && custom_biller.groups.reload.none?
      custom_biller.destroy
    end
  end
end
