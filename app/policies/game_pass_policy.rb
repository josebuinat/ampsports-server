class GamePassPolicy < ApplicationPolicy
  class Scope < Scope
    def index
      show
    end

    def show
      if user.can?(:game_passes, :read)
        scope
      else
        scope.none
      end
    end

    def update
      if user.can?(:game_passes, :edit)
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

    def available_for_select
      show
    end

    def select_options
      show
    end
  end

  def create?
    user.can?(:game_passes, :edit)
  end

  def available_for_select?
    user.can?(:game_passes, :read)
  end
end
