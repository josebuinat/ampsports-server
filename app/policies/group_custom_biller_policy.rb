class GroupCustomBillerPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def show
      if user.can?(:group_custom_billers, :read)
        scope
      else
        scope.none
      end
    end

    def update
      if user.can?(:group_custom_billers, :edit)
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
  end

  def create?
    user.can?(:group_custom_billers, :edit)
  end
end
