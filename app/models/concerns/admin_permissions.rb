# represents personal authorization rules for Coaches or Admins
# actual mapping of this rules to controllers actions is in the /app/policies
module AdminPermissions
  extend ActiveSupport::Concern

  PERMISSIONS = [
    :profile,
    :profile_coach_calendar,
    :permissions,
    :search,
    :dashboard,
    :calendar, # reservations and other calendar related stuff
    :modify_paid_reservations,
    :customers,
    :discounts,
    :recurring_reservations,
    :game_passes,
    :email_lists,
    :email_customization,
    :email_history,
    :groups,
    :group_classifications,
    :group_custom_billers,
    :coaches,
    :invoice_drafts,
    :invoice_unpaid,
    :invoice_paid,
    :invoice_create,
    :reports,
    :venues,
    :courts,
    :prices,
    :holidays,
    :colors,
    :company,
    :admins,
    :activity_logs,
    :settings,
    :company_email_notifications,
  ].freeze

  ACTIONS = %w(read edit)

  included  do
    has_many :user_permissions, as: :owner

    before_save :reset_permissions, if: :level_changed?

    def can?(entity, action)
      return true if god?
      return false if !PERMISSIONS.include?(entity) || !ACTIONS.include?(action.to_s)

      permissions[entity].include?(action.to_s)
    end

    def coach?
      self.is_a? Coach
    end

    # { courts: ['read'], groups: ['read', 'edit'], admins: [] }
    def permissions
      return god_permissions if god?
      return generate_default_permissions if user_permissions.none?

      grouped_permissions = user_permissions.order(value: :desc).group_by(&:permission)

      PERMISSIONS.map do |permission|
        [permission, grouped_permissions[permission.to_s].to_a.map(&:value)]
      end.to_h
    end

    # { 'courts' => ['read'], :groups => ['read', 'edit'], 'admins' [] }
    def permissions=(permissions_params)
      # don't even allow to write for gods
      return permissions if god?

      PERMISSIONS.each do |permission|
        raw_actions = permissions_params[permission] || permissions_params[permission.to_s]
        actions = ACTIONS & raw_actions.to_a.map(&:to_s)

        # enforced permissions, can read profile always
        actions.push('read').uniq! if [:profile, :profile_coach_calendar].include?(permission)

        ACTIONS.each do |action|
          if actions.include?(action)
            user_permissions.find_or_create_by(permission: permission.to_s, value: action)
          else
            user_permissions.where(permission: permission.to_s, value: action).destroy_all
          end
        end
      end
    end

    def reset_permissions
      self.user_permissions.destroy_all
    end

    def generate_default_permissions
      case level
      when 'guest'
        guest_permissions
      when 'base'
        base_permissions
      when 'editor'
        editor_permissions
      when 'manager'
        manager_permissions
      when 'cashier'
        cashier_permissions
      when 'god'
        god_permissions
      else
        no_permissions
      end
    end

    def god_permissions
      PERMISSIONS.map { |permission| [permission, ACTIONS] }.to_h
    end

    def manager_permissions
      is_coach = self.is_a?(Coach)
      god_permissions.merge(
        admins: is_coach ? [] : ['read'],
        company: [],
        permissions: ['read'],
        coaches: is_coach ? ['read'] : ACTIONS
      )
    end

    def cashier_permissions
      guest_permissions.merge(
        calendar: ACTIONS,
        discouts: ACTIONS
      )
    end

    def guest_permissions
      PERMISSIONS.map { |permission| [permission, ['read']] }.to_h.merge(
        company: [],
        admins: [],
        permissions: []
      )
    end

    def base_permissions
      no_permissions.merge(
        profile: ACTIONS,
        profile_coach_calendar: ['read'],
      )
    end

    def editor_permissions
      guest_permissions.merge(
        calendar: ACTIONS,
        profile: ACTIONS,
        profile_coach_calendar: ACTIONS,
      )
    end

    def no_permissions
      PERMISSIONS.map { |permission| [permission, []] }.to_h
    end

    def self.permitted_permissions
      PERMISSIONS.map { |permission| [permission, []] }.to_h
    end
  end
end
