# represents has_and_belongs_to_many association between groups and users
class GroupMember < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
  delegate :full_name, :email, to: :user
  delegate :current_season, to: :group, allow: nil

  validates :user, :group, presence: true
  validates :user, uniqueness: { scope: :group_id }
  validate :validate_filled_group

  after_create :find_or_create_subscription, if: :seasonal?
  after_create :create_participations

  after_create :notify_member_added
  after_destroy :notify_member_removed

  def subscriptions
    group.subscriptions.where(user: user)
  end

  def has_paid_subscription_covering?(start_time, end_time)
    subscriptions.where(is_paid: true).
                  where(group_season: group.seasons_covering(start_time, end_time)).
                  any?
  end

  def find_or_create_subscription
    current_season.group_subscriptions.find_or_create_by(user: user)
  end

  def seasonal?
    group.season? && current_season.present?
  end

  private

  def validate_filled_group
    unless group.members.count < group.max_participants
      errors.add :group, :group_is_full
    end
  end

  def create_participations
    group.reservations.future.each do |reservation|
      reservation.build_participation_for(self)&.save
    end
  end

  def notify_member_added
    GroupMailer.added_to_the_group(group, user).deliver_later
  end

  def notify_member_removed
    GroupMailer.removed_from_the_group(group, user).deliver_later
  end
end
