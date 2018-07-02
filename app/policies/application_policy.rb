class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def coach?
    user.is_a? Coach
  end

  def admin?
    user.is_a? Admin
  end

  def god?
    admin? && user.god?
  end

  def manager?
    user.manager? || god?
  end

  def editor_coach?
    coach? && user.editor?
  end

  def cashier?
    admin? && user.cashier?
  end

  def guest?
    admin? && user.guest?
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end
