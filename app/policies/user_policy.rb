class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def show
      if user.can?(:customers, :read) ||
          user.can?(:invoice_create, :edit) ||
          user.can?(:email_lists, :edit)
        scope
      else
        scope.none
      end
    end

    def update
      if user.can?(:customers, :edit)
        scope
      else
        scope.none
      end
    end

    def destroy
      update
    end

    def select_options
      if user.can?(:customers, :read) ||
          user.can?(:calendar, :edit) ||
          user.can?(:recurring_reservations, :edit) ||
          user.can?(:game_passes, :edit) ||
          user.can?(:email_lists, :edit) ||
          user.can?(:groups, :edit) ||
          user.can?(:colors, :edit) ||
          (user.can?(:profile_coach_calendar, :edit) && user.coach?)
        scope
      else
        scope.none
      end
    end
  end

  def create?
    user.can?(:customers, :edit)
  end

  def import?
    create?
  end
end
