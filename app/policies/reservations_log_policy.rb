class ReservationsLogPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      if user.can?(:calendar, :read) || user.can?(:recurring_reservations, :read)
        scope
      elsif user.can?(:profile_coach_calendar, :read) && user.coach?
        scope.joins(:reservation).where(reservations: { user_id: user.id, user_type: 'Coach' })
      else
        scope.none
      end
    end
  end
end
