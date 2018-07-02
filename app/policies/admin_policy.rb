class AdminPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def show
      if user.can?(:admins, :read)
        scope
      elsif user.can?(:profile, :read) && user.is_a?(Admin)
        scope.where(id: user.id)
      else
        scope.none
      end
    end

    def update
      if user.can?(:admins, :edit)
        scope
      elsif user.can?(:profile, :edit) && user.is_a?(Admin)
        scope.where(id: user.id)
      else
        scope.none
      end
    end

    def destroy
      if user.god?
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
      if user.can?(:calendar, :edit)
        scope
      else
        scope.none
      end
    end
  end

  def create?
    user.can?(:admins, :edit)
  end

  def permitted_attributes
    attributes = [:first_name, :last_name, :email, :birth_date, :admin_ssn, :clock_type]

    if user.can?(:permissions, :edit) && record && user != record
      attributes.push(:level, permissions: Admin.permitted_permissions)
    end

    attributes
  end
end
