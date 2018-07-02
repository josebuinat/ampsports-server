class GroupClassificationPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def select_options
      show
    end

    def show
      if user.can?(:group_classifications, :read) || user.can?(:groups, :read)
        scope
      else
        scope.none
      end
    end

    def update
      if user.can?(:group_classifications, :edit)
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
    user.can?(:group_classifications, :edit)
  end
end
