class Coach::SalaryRatePolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def show
      if user.can?(:coaches, :read)
        scope
      elsif user.can?(:profile, :read)
        scope.where(coach: user)
      else
        scope.none
      end
    end

    def update
      if user.can?(:coaches, :edit)
        scope
      elsif user.can?(:profile, :edit)
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
  end

  def owner?
    record.coach_id == user.id
  end

  def create?
    (user.can?(:profile, :edit) && owner?) || user.can?(:coaches, :edit)
  end
end
