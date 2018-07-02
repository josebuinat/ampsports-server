class CoachPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def download
      show
    end

    def show
      if user.can?(:coaches, :read)
        scope
      elsif user.can?(:profile, :read) && user.is_a?(Coach)
        scope.where(id: user.id)
      else
        scope.none
      end
    end

    def update
      if user.can?(:coaches, :edit)
        scope
      elsif user.can?(:profile, :edit) && user.is_a?(Coach)
        scope.where(id: user.id)
      else
        scope.none
      end
    end

    def destroy
      if user.can?(:coaches, :edit)
        scope
      else
        scope.none
      end
    end

    def destroy_many
      destroy
    end

    def permissions
      if user.can?(:permissions, :edit)
        scope
      else
        scope.none
      end
    end

    def select_options
      if user.can?(:coaches, :read) ||
          user.can?(:calendar, :edit) ||
          user.can?(:groups, :edit)
        scope
      else
        scope.none
      end
    end

    def available_select_options
      select_options
    end
  end

  def create?
    user.can?(:coaches, :edit)
  end

  def permitted_attributes
    attributes = [
      :first_name,
      :last_name,
      :email,
      :phone_number,
      :address,
      :experience,
      :description,
      :clock_type,
      sports: []
    ]

    if record && user == record
      attributes.push(*Coach.password_fields)
    end

    if user.can?(:permissions, :edit) && record && user != record
      attributes.push(:level, permissions: Coach.permitted_permissions)
    end

    attributes
  end
end
