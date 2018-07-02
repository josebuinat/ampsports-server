class DiscountPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def show
      if user.can?(:discounts, :read)
        scope
      else
        scope.none
      end
    end

    def update
      if user.can?(:discounts, :edit)
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

    def remove_from_user
      update
    end

    def add_to_user
      update
    end

    def select_options
      if user.can?(:discounts, :read) || user.can?(:colors, :edit)
        scope
      else
        scope.none
      end
    end
  end

  def create?
    user.can?(:discounts, :edit)
  end
end
