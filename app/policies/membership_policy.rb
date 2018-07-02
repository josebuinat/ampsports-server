class MembershipPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def show
      if user.can?(:recurring_reservations, :read)
        scope
      else
        scope.none
      end
    end

    def update
      if user.can?(:recurring_reservations, :edit)
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

    def renew_many
      update
    end
  end

  def create?
    user.can?(:recurring_reservations, :edit)
  end

  def import?
    create?
  end
end
