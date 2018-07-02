class Coach::ReservationPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      if user.can?(:coaches, :read)
        scope
      elsif (user.can?(:profile, :read) ||
             user.can?(:profile_coach_calendar, :read)) && user.coach?
        scope.for_coach(user)
      else
        scope.none
      end
    end

    def unavailable_slots
      index
    end
  end
end
