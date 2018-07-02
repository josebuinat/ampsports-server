class HolidayPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def show
      if user.can?(:holidays, :read)
        scope
      else
        scope.none
      end
    end

    def all_for_calendar
      if user.can?(:holidays, :read) ||
           user.can?(:calendar, :read) ||
           (user.can?(:profile_coach_calendar, :read) && user.coach?)
        scope
      else
        scope.none
      end
    end

    def update
      if user.can?(:holidays, :edit)
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
  end

  def create?
    user.can?(:holidays, :edit)
  end
end
