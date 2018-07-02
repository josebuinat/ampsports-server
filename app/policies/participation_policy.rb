class ParticipationPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def show
      if user.can?(:calendar, :read)
        scope
      elsif user.can?(:profile_coach_calendar, :read) && user.coach?
        scope.where(reservation: user.owned_reservations)
      else
        scope.none
      end
    end

    def update
      if user.can?(:calendar, :edit)
        scope
      elsif user.can?(:profile_coach_calendar, :edit) && user.coach?
        scope.where(reservation: user.owned_reservations)
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

    def mark_paid_many
      update
    end
  end

  def create?
    user.can?(:calendar, :edit) ||
      (user.can?(:profile_coach_calendar, :edit) && user.coach? && (record.user == user))
  end
end
