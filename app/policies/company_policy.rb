class CompanyPolicy < ApplicationPolicy
  class Scope < Scope
    def show
      if user.god? || user.can?(:company, :read)
        scope
      else
        scope.none
      end
    end

    def update
      if user.god? || user.can?(:company, :edit)
        scope
      else
        scope.none
      end
    end

    def remove_user_from_quick_invoicing
      if user.can?(:invoice_create, :edit) || user.can?(:company, :edit)
        scope
      else
        scope.none
      end
    end
  end

  def create?
    god?
  end

  def read_email_notifications_settings?
    user.can?(:company_email_notifications, :read)
  end

  def edit_email_notifications_settings?
    user.can?(:company_email_notifications, :edit)
  end
end
