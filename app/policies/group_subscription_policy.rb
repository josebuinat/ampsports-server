class GroupSubscriptionPolicy < ApplicationPolicy
  class Scope < Scope
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

    def destroy
      if user.can?(:groups, :edit)
        scope
      else
        scope.none
      end
    end

    def destroy_many
      destroy
    end

    def mark_paid_many
      if user.can?(:groups, :edit)
        scope
      else
        scope.none
      end
    end

    def mark_unpaid_many
      mark_paid_many
    end
  end
end
