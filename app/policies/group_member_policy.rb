class GroupMemberPolicy < ApplicationPolicy
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
  end

  def create?
    user.can?(:groups, :edit)
  end
end
