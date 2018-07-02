class API::ReservationsController < API::BaseController
  include ActionController::MimeResponds
  before_action :authenticate_request!, except: [:payment, :download]
  before_action :set_reservation, only: [:download, :destroy, :payment, :resell]
  around_action :use_timezone, only: [:download, :destroy, :payment, :resell]

  def download
    calendar = Icalendar::Calendar.new
    calendar.add_event(@reservation.to_ics)
    send_data calendar.to_ical, filename: "#{@reservation.id}.ics", disposition: 'attachment'
  end

  def create
    sanitizer = ReservationSanitizer.new(@current_user, params)
    sanitizer.create_reservations

    if sanitizer.valid?
      render json: { message: I18n.t('api.reservations.success') }, status: :ok
    else
      render json: { errors: sanitizer.errors }, status: :unprocessable_entity
    end
  end

  def index
    # Timezone for this action is set in the jbuilder view file
    @reservations_past = index_filter @current_user.past_reservations, 'reverse'
    @reservations_future = index_filter @current_user.future_reservations
    @recurring_past = index_filter @current_user.past_memberships, 'reverse'
    @recurring_future = index_filter @current_user.future_memberships
    @recurring_reselling_past = index_filter @current_user.reselling_memberships_past, 'reverse'
    @recurring_reselling_future = index_filter @current_user.reselling_memberships_future
    @recurring_resold_past = index_filter @current_user.resold_memberships_past, 'reverse'
    @recurring_resold_future = index_filter @current_user.resold_memberships_future
    @lessons_past = index_filter @current_user.lessons.past, 'reverse'
    @lessons_future = index_filter @current_user.lessons.future
    @recurring_and_regular_reservations_future =
      (@reservations_future + @recurring_future).sort_by(&:start_time)
    @recurring_and_regular_reservations_past =
      (@reservations_past + @recurring_past).sort_by(&:start_time).reverse
  end

  def index_filter(scope, sorting = 'normal')
    # can't preload groups stuff here, though
    scope = scope.includes(:user, :court, :company, :participations, :membership, :coaches,
                            venue: [:primary_photo, :photos])
    scope = scope.for_sport(params[:sport]) if params[:sport].present?
    scope = scope.sort_by(&:start_time)
    scope = scope.reverse if sorting == 'reverse'
    scope
  end

  def destroy
    participation = @reservation.participation_for(current_user)
    if @reservation.cancelable? && @reservation.user == current_user
      @reservation.cancel(current_user)
      ActivityLog.record_log(:reservation_cancelled, @reservation.company.id, current_user, @reservation)
      render json: { message: I18n.t('api.reservations.reservation_cancelled') }, status: :ok
    elsif @reservation.cancelable? && participation
      participation.cancel
      ActivityLog.record_log(:participation_cancelled, @reservation.company.id, current_user, @reservation)
      render json: { message: I18n.t('api.reservations.participation_cancelled') }, status: :ok
    else
      render json: { errors: { '0' => I18n.t('api.reservations.reservation_not_cancelled') } }, status: :unprocessable_entity
    end
  end

  def payment
    if @reservation.valid? && @reservation.pay_with(**payment_params)
      ActivityLog.record_log(:reservation_updated, @reservation.company.id, nil, @reservation, request.remote_ip)
      head :ok
    else
      render json: { errors: @reservation.errors }, status: :unprocessable_entity
    end
  end

  def resell
    reservation = @current_user.reservations.find(params[:reservation_id])

    if reservation.resold?
      render json: { errors: [I18n.t('api.reservations.reservation_already_resold')] }, status: :bad_request
    else
      if reservation.reselling?
        updated = reservation.update(reselling: false)
        message = I18n.t('api.reservations.reservation_was_withdrawn')
      elsif reservation.resellable?
        updated = reservation.update(reselling: true)
        message = I18n.t('api.reservations.reservation_put_on_resell')

        SegmentAnalytics.user_resell(reservation, current_user)
      end
      if updated
        ActivityLog.record_log(:reservation_updated, reservation.company.id, @current_user, reservation)
        render json: { message: message }, status: :ok
      else
        errors = reservation.errors.full_messages.any? ?
                   reservation.errors.full_messages : [I18n.t('api.reservations.not_eligible_request')]
        render json: { errors: errors }, status: :unprocessable_entity
      end
    end
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:reservation_id] || params[:id])
  end

  def use_timezone
    venue = @reservation&.venue
    if venue
      Time.use_zone(venue.timezone) { yield }
    else
      yield
    end
  end

  def payment_params
    params.permit(:card_token, :game_pass_id).symbolize_keys
  end
end
