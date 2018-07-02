class GroupPolicy < ApplicationPolicy
  class Scope < Scope
    def groups_options
      if user.can?(:groups, :read) || user.can?(:group_custom_billers, :edit)
        scope
      else
        scope.none
      end
    end

    def index
      show
    end

    def show
      if user.can?(:groups, :read)
        scope
      else
        scope.none
      end
    end

    def update
      if user.can?(:groups, :edit)
        scope
      else
        scope.none
      end
    end

    def destroy
      update
    end

    def destroy_many
      update
    end

    def duplicate_many
      update
    end

    def select_options
      if user.can?(:groups, :read) ||
          user.can?(:calendar, :edit) ||
          user.can?(:recurring_reservations, :edit) ||
          user.can?(:group_custom_billers, :edit)
        scope
      elsif user.can?(:profile_coach_calendar, :edit) && user.coach?
        scope.where(coach: user)
      else
        scope.none
      end
    end
  end

  def create?
    user.can?(:groups, :edit)
  end
end
