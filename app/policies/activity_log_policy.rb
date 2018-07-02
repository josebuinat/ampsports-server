class ActivityLogPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      if user.can?(:activity_logs, :read)
        scope
      else
        scope.none
      end
    end
  end
end
