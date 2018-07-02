class Admin::Venues::Reservations::ParticipationsController < Admin::BaseController
  around_action :use_timezone

  def index
    @participations = authorized_scope(reservation.participations).
                        active.includes(:user, reservation: :user)
    @participations = @participations.paginate(page: params[:page])
  end

  def show
    participation
  end

  def create
    @participation = authorize reservation.participations.build(create_params)

    if @participation.save
      render 'show', status: :created
    else
      render json: { errors: @participation.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if participation.cancel
      render json: [participation.id]
    else
      head :unprocessable_entity
    end
  end

  def destroy_many
    cancelled = many_participations.select do |participation|
      participation.cancel
    end

    render json: cancelled.map(&:id)
  end

  def mark_paid_many
    marked_paid = many_participations.includes(reservation: :user).select do |participation|
      participation.mark_paid
    end

    render json: marked_paid.map(&:id)
  end

  private

  def company
    current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end

  def reservation
    @reservation ||= venue.reservations.find(params[:reservation_id])
  end

  def participation
    @participation ||= authorized_scope(reservation.participations).active.find(params[:id])
  end

  def many_participations
    @many_participations ||= authorized_scope(reservation.participations).
                                active.where(id: params[:participation_ids])
  end

  def create_params
    params.require(:participation).permit(:user_id, :price)
  end
end
