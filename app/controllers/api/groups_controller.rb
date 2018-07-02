class API::GroupsController < API::BaseController
  before_action :authenticate_request!

  def index
    @groups = current_user.groups.base_includes.order(:created_at)
  end

  def show
    @group = current_user.groups.
                          includes(members: :user, reservations: [ :membership, court: :venue ]).
                          find(params[:id])
  end
end
