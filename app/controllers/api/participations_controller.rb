class API::ParticipationsController < API::BaseController
  before_action :authenticate_request!

  def index
    @participations = current_user.
                        participations.
                        active.
                        reservation_includes.
                        order(:created_at)
  end

  def show
    participation
  end

  def cancel
    if participation.cancel
      render 'show'
    else
      head :unprocessable_entity
    end
  end

  private

  def participation
    @participation ||= current_user.participations.active.find(params[:id])
  end
end
