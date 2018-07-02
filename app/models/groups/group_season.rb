class GroupSeason < ActiveRecord::Base
  include TimeSpreadable
  time_spreadable_columns('start_date', 'end_date', as_dates: true)

  belongs_to :group
  has_many :group_subscriptions, dependent: :destroy
  has_one :venue, through: :group
  has_one :company, through: :venue

  validates :group, :start_date, :end_date, presence: true
  validate :validate_seasonal_group
  validate :validate_overlapping

  before_save :reset_current_for_other_seasons, if: :current?
  after_save :create_subscriptions, if: :became_current?

  scope :current, -> { where(current: true) }
  scope :covering, ->(from, to) { where(arel_table[:start_date].lteq(from).and(arel_table[:end_date].gteq(to))) }
  scope :groups, ->(groups) { where(group_id: groups.select(:id)) }

  def start_date=(date)
    self[:start_date] = TimeSanitizer.input(date.to_s).to_date rescue nil
  end

  def end_date=(date)
    self[:end_date] = TimeSanitizer.input(date.to_s).to_date rescue nil
  end

  def start_time
    Time.use_zone(venue.timezone) do
      start_date.in_time_zone.utc
    end
  end

  def end_time
    Time.use_zone(venue.timezone) do
      end_date.in_time_zone.end_of_day.utc
    end
  end

  def get_participation_price
    participation_price || group.participation_price
  end

  def build_duplicate
    GroupSeason.new(
      **[:start_date, :end_date, :current, :participation_price].
         map { |attr| [attr, public_send(attr)] }.to_h
    )
  end

  private

  def validate_seasonal_group
    unless group&.season?
      errors.add :group, :not_seasonal
    end
  end

  def validate_overlapping
    return unless group.present?

    if group.seasons.where.not(id: self.id).overlapping(start_date, end_date).any?
      errors.add :start_date, :has_overlapping
    end
  end

  def reset_current_for_other_seasons
    group.seasons.where.not(id: self.id).update_all(current: false)
  end

  def became_current?
    current_changed? && current?
  end

  def create_subscriptions
    group.members.each do |member|
      member.find_or_create_subscription
    end
  end
end
