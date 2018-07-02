class API::ParticipationCreditsController < API::BaseController
  before_action :authenticate_request!

  def index
    @participation_credits = current_user.participation_credits.
                                          includes(:group_classification).
                                          order(:created_at)
  end

  def show
    participation_credit

    @applicable_reservations = participation_credit.
                                  applicable_reservations.
                                  includes(:membership,
                                            court: :venue,
                                            user: [
                                              :owner,
                                              :coaches,
                                              :classification,
                                              :seasons
                                            ])
  end

  def use
    if participation_credit.use_for(reservation)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def participation_credit
    @participation_credit = current_user.participation_credits.find(params[:id])
  end

  def reservation
    @reservation ||= participation_credit.company.reservations.find(params[:reservation_id])
  end
end
