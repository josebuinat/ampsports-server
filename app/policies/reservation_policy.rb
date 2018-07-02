class ReservationPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def show
      # slightly broader context for coaches than it should be, but overall it's fine
      if user.can?(:calendar, :read) || user.can?(:profile_coach_calendar, :read)
        scope
      else
        scope.none
      end
    end

    def update
      if user.can?(:calendar, :edit)
        scope
      elsif user.can?(:profile_coach_calendar, :edit) && user.coach?
        scope.where(coach: user)
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

    def copy
      update
    end

    def toggle_resell_state
      if user.can?(:calendar, :edit) || user.can?(:recurring_reservations, :edit)
        scope
      elsif user.can?(:profile_coach_calendar, :edit) && user.coach?
        scope.where(user_id: user.id, user_type: 'Coach')
      else
        scope.none
      end
    end

    def resell_to_user
      update
    end

    def future_reservations
      show
    end

    def reservations_between
      show
    end

    def mark_salary_paid_many
      update
    end
  end

  def index?
    user.can?(:calendar, :read)
  end

  def create?
    return true if user.can?(:calendar, :edit)
    # for reservation instances we check access, for reservations as a class we don't
    has_access_to_reservation = record.kind_of?(Class) ? true : record.user == user
    user.can?(:profile_coach_calendar, :edit) && user.coach? && has_access_to_reservation
  end

  def update?
    # no additional checks here, as record is fetched through scope
    return true unless record.paid?
    user.can?(:modify_paid_reservations, :edit)
  end
end
# to avoid warning: toplevel constant ReservationPolicy referenced by Coach::ReservationPolicy
require_dependency 'coach/reservation_policy'
