class CourtPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def show
      if user.can?(:courts, :read)
        scope
      else
        scope.none
      end
    end
    def update
      if user.can?(:courts, :edit)
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

    def select_options
      if user.can?(:courts, :read) ||
          user.can?(:calendar, :read) ||
          user.can?(:recurring_reservations, :edit) ||
          user.can?(:prices, :edit) ||
          user.can?(:holidays, :edit) ||
          (user.can?(:profile_coach_calendar, :read) && user.coach?)
        scope
      else
        scope.none
      end
    end

    def available_select_options
      select_options
    end

    def calendar_resources
      select_options
    end

    def prices_at
      select_options
    end

    def calendar_print
      select_options
    end
  end

  def create?
    user.can?(:courts, :edit)
  end

  def active?
    user.can?(:courts, :read) ||
      user.can?(:calendar, :read) ||
      user.can?(:profile_coach_calendar, :read)
  end

  def available_indexes?
    user.can?(:courts, :edit)
  end
end
