class PricePolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def show
      if user.can?(:prices, :read)
        scope
      else
        scope.none
      end
    end

    def update
      if user.can?(:prices, :edit)
        scope
      else
        scope.none
      end
    end

    def destroy
      update
    end
  end

  def create?
    user.can?(:prices, :edit)
  end
end
