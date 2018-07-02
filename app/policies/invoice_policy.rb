class InvoicePolicy < ApplicationPolicy
  class Scope < Scope
    def index
      if user.can?(:invoice_drafts, :read) ||
        user.can?(:invoice_unpaid, :read) ||
        user.can?(:invoice_paid, :read)
        scope
      else
        scope.none
      end
    end

    def show
      index
    end

    def print_all
      index
    end

    def update
      if user.can?(:invoice_drafts, :edit)
        scope
      else
        scope.none
      end
    end

    def destroy_many
      update
    end

    def send_all
      update
    end

    def unsend_all
      if user.can?(:invoice_unpaid, :edit)
        scope
      else
        scope.none
      end
    end

    def mark_paid
      if user.can?(:invoice_unpaid, :edit)
        scope
      else
        scope.none
      end
    end
  end

  def create?
    user.can?(:invoice_create, :edit)
  end

  def create_drafts?
    user.can?(:invoice_create, :edit)
  end

  def authorized_type_scope(type)
    type = type.to_s

    permitted_types.include?(type) ? type : 'none'
  end

  def permitted_types
    types = []
    types << 'drafts' if user.can?(:invoice_drafts, :read)
    types << 'unpaid' if user.can?(:invoice_unpaid, :read)
    types << 'paid' if user.can?(:invoice_paid, :read)

    types
  end
end
