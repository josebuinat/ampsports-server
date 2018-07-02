class EmailListPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      if user.can?(:email_lists, :read)
        scope
      else
        scope.none
      end
    end

    def update
      if user.can?(:email_lists, :edit)
        scope
      else
        scope.none
      end
    end

    def not_listed
      index
    end

    def add_many
      update
    end

    def remove_many
      update
    end

    def destroy
      update
    end

    def select_options
      index
    end
  end

  def create?
    user.can?(:email_lists, :edit)
  end
end
