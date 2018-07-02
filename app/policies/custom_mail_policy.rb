class CustomMailPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      if user.can?(:email_history, :read)
        scope
      else
        scope.none
      end
    end
  end

  def create?
    # Well, yeah, we agreed to allow compose custom emails if lists are writable, not the history
    user.can?(:email_lists, :edit)
  end
end
