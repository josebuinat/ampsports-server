module Punditable extend ActiveSupport::Concern
  included do
    include Pundit

    rescue_from Pundit::NotAuthorizedError, :with => :forbidden_request

    # override in the controller
    def pundit_user
      @current_user
    end

    def authorize(record, query = nil)
      record if super(record, query)
    end

    def authorized_scope(scope, query = nil, policy = nil)
      query ||= params[:action].to_s
      @_pundit_policy_scoped = true

      if policy
        policy::Scope.new(pundit_user, scope).public_send(query)
      else
        scope_policy(scope).public_send(query)
      end
    end

    def scope_policy(scope)
      scope_policies[scope] ||= Pundit::PolicyFinder.new(scope).scope!.new(pundit_user, scope)
    end

    def scope_policies
      @_pundit_scope_policies ||= {}
    end
  end
end
