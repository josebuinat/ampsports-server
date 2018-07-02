# Handles reservation group participations
module ReservationParticipations
  extend ActiveSupport::Concern

  included do
    has_many :participations, dependent: :destroy, inverse_of: :reservation

    before_create :assign_zero_price, if: :for_admin_group?
    before_create :assign_member_participants, if: :for_group?
    after_create :update_participations_count

    scope :groups, ->(groups) { where(user_type: 'Group', user_id: groups.select(:id)) }

    # find reservations for user or his groups
    # users can be single user
    def self.users_with_groups(users)
      t = arel_table
      users = [users] if users.is_a?(User)

      group_ids = Group.where(owner: users).pluck(:id)

      where(t[:user_id].in(users.map(&:id)).and(t[:user_type].eq('User')).
              or(t[:user_id].in(group_ids).and(t[:user_type].eq('Group'))))
    end
  end

  def for_group?
    user.is_a? Group
  end

  def group
    for_group? && user
  end

  def for_admin_group?
    for_group? && user.admin_owned?
  end

  def fetch_owner_id
    for_group? ? user.owner_id : user&.id
  end

  def participation_price
    return unless for_group?

    case group.priced_duration
    when 'session'
      group.participation_price
    when 'hour'
      group.participation_price * hours
    when 'season'
      group.participation_price # dummy, will set zero if subscribed, and something else otherwise
    end
  end

  def participation_rate
    return unless for_group?

    "#{participations_count}/#{group.max_participants}"
  end

  def update_participations_count
    update_column(:participations_count, participations.active.count)
  end

  def build_participation_for(member)
    if !group.season?
      participations.build(user: member.user)
    else
      paid = member.has_paid_subscription_covering?(start_time, end_time)
      participations.build(user: member.user, is_paid: paid, price: 0)
    end
  end

  private


  def assign_zero_price
    # to be sure, assign paid status also
    assign_attributes(is_paid: true, payment_type: :paid, price: 0)
  end

  def assign_member_participants
    group.members.includes(:user).each do |member|
      build_participation_for(member)
    end
  end

end
