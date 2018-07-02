class Admin::Venues::ReservationsController < Admin::BaseController
  # it's important to run these method as a before_action, because
  # this method make premature render (and thus action call may not be required at all)
  before_action :create_reservation_owner, only: [:create, :resell_to_user]
  around_action :use_timezone

  # action for calendar
  def index
    authorize Reservation
    render json: venue.reservations_shared_courts_json(start_date, end_date)
  end

  def show
    reservation
  end

  def create
    authorize Reservation
    saved, failed = sanitized_bookings.map do |booking_params|
      Reservation.new(booking_params)
    end.partition do |reservation|
      reservation.save
    end

    saved.map(&:track_booking)

    if failed.blank?
      ActivityLog.record_log(:reservation_created, company.id, current_admin, saved)
      render json: { saved: saved }, status: :created
    else
      render json: { failed: failed.map { |x| x.errors.full_messages }, saved: saved }, status: :unprocessable_entity
    end
  end

  def update
    authorize reservation
    if reservation.update(update_params)
      ActivityLog.record_log(:reservation_updated, company.id, current_admin, reservation)
      render 'show'
    else
      render json: { errors: reservation.errors }, status: :unprocessable_entity
    end
  end

  def copy
    copied_attributes = %w(user_id user_type price note participants classification_id).map do |attribute|
      [attribute, reservation.public_send(attribute)]
    end

    @copy =  Reservation.new(
      copied_attributes.to_h
    )
    @copy.assign_attributes(copy_params)

    if @copy.save
      ActivityLog.record_log(:reservation_created, company.id, current_admin, @copy)
      render 'show', status: :created
    else
      render json: { errors: @copy.errors }, status: :unprocessable_entity
    end
  end

  def toggle_resell_state
    if reservation.update_attributes(resell_params)
      ActivityLog.record_log(:reservation_updated, company.id, current_admin, reservation)
      if reservation.reselling?
        # state after update, so it's now reselling -> it was withdrawn
        SegmentAnalytics.withdraw_resell_booking(reservation, current_admin)
      else
        SegmentAnalytics.admin_resell(reservation, current_admin)
      end
      render 'show'
    else
      render json: { errors: reservation.errors }, status: :unprocessable_entity
    end
  end

  def resell_to_user
    if reservation.resell_to_user(create_reservation_owner, true)
      ActivityLog.record_log(:reservation_updated, company.id, current_admin, reservation)
      SegmentAnalytics.sold_resell_booking(reservation, current_admin)
      render 'show'
    else
      render json: { errors: reservation.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    reservation.override_should_send_emails = params[:override_should_send_emails]
    reservation.cancel(current_admin, params[:skip_refund].present?)
    ActivityLog.record_log(:reservation_cancelled, company.id, current_admin, reservation)
    render json: [reservation.id]
  end

  def mark_salary_paid_many
    marked_paid = many_reservations.select do |reservation|
      reservation.mark_coach_salary_paid(coach)
    end

    render json: marked_paid.map(&:id)
  end

  private

  def resell_params
    will_be_reselling = !reservation.reselling?
    {
      update_by_admin: true,
      reselling: will_be_reselling,
    }
  end

  def sanitized_bookings
    params.require(:reservations).map do |reservation|
      reservation.permit(:court_id, :price, :classification_id, coach_ids: []).merge({
        start_time:    TimeSanitizer.input("#{reservation[:date]} #{reservation[:start_tact]}"),
        end_time:      TimeSanitizer.input("#{reservation[:date]} #{reservation[:end_tact]}"),
        note:          params.dig(:meta, :note).to_s,
        override_should_send_emails: params.dig(:meta, :override_should_send_emails),
        user:          create_reservation_owner,
        participant_ids: params[:participant_ids],
        payment_type: :unpaid,
        booking_type: :admin,
      })
    end
  end

  def create_reservation_owner
    return @create_reservation_owner if @create_reservation_owner.present?
    user_type = params.dig(:user, :type)
    user_id = params.dig(:user, :id)
    if user_type == 'User'
      @create_reservation_owner = if user_id.present?
        company.users.find(user_id).tap do |user|
          venue.venue_user_connectors.create user: user
        end
      else
        # ask to create a new user; but user may already present in the system
        existing_user = User.find_by email: params.dig('user', 'email')
        if existing_user
          # then just connect this user
          venue.add_customer(existing_user, track_with_actor: current_admin)
          existing_user
        else
          user_params = params.require(:user).permit(:first_name, :last_name, :email, :phone_number, :locale)
          user_params[:locale] = I18n.locale if user_params[:locale].blank?
          # connected to venue like this because user will need .venues in the mailer callback
          user_params[:venues] = [venue]
          user = User.create(user_params)
          SegmentAnalytics.admin_created_user(user, current_admin)
          SegmentAnalytics.user_added_to_venue_via_admin(user, venue, current_admin)
          user
        end
      end
    elsif user_type == 'Group'
      @create_reservation_owner = company.groups.find_by(id: user_id)
    elsif user_type == 'Coach'
      @create_reservation_owner = company.coaches.find_by(id: user_id)
    elsif user_type == 'Guest'
      @create_reservation_owner = Guest.create(params.require(:user).permit(:full_name))
    else
      raise WrongActionError
    end

    # hate premature return, but is there a better way if we create 2 entities within 1 action?
    if @create_reservation_owner.nil?
      render json: { errors: { 'user.id' => I18n.t('api.record_not_found') } }, status: :unprocessable_entity
      return false
    end
    unless @create_reservation_owner.persisted?
      # frontend expects response in a format "user.field: [error1, error2]"
      errors = @create_reservation_owner.errors.to_hash.transform_keys { |key| "user.#{key}" }
      render json: { errors: errors}, status: :unprocessable_entity
      return false
    end

    @create_reservation_owner
  end

  def update_params
    reservation_params = params.require(:reservation)

    start_time = reservation_params[:date].present? && reservation_params[:start_tact].present? ?
      TimeSanitizer.input("#{reservation_params[:date]} #{reservation_params[:start_tact]}") : nil

    end_time = reservation_params[:date].present? && reservation_params[:end_tact].present? ?
      TimeSanitizer.input("#{reservation_params[:date]} #{reservation_params[:end_tact]}") : nil

    reservation_params.
      permit(
        :price, :amount_paid, :court_id, :user_id, :date, :note, :classification_id,
        :game_pass_id, :paid_in_full, :override_should_send_emails, :coach_ids, coach_ids: [],
        participant_connections_attributes: [:id, :price, :amount_paid, :user_id, :_destroy]
      ).
      merge({
        # this to would not get merged if they are nil
        start_time: start_time,
        end_time: end_time
      }.reject { |_k, v| v.nil? }).
      merge({
        update_by_admin: true,
        recalculate_price_on_save: reservation_params[:price].blank? && !reservation.for_group?
      })
  end

  def copy_params
    reservation_params = params.require(:reservation)
    reservation_params.permit(:court_id).merge({
      start_time: TimeSanitizer.input("#{reservation_params[:date]} #{reservation_params[:start_tact]}"),
      end_time: TimeSanitizer.input("#{reservation_params[:date]} #{reservation_params[:end_tact]}"),
      payment_type: :unpaid,
      booking_type: :admin,
    })
  end

  def reservation
    @reservation ||= authorized_scope(venue.reservations).find(params[:id])
  end

  def many_reservations
    @many_reservations ||= authorized_scope(venue.reservations).where(id: params[:reservation_ids])
  end

  # params = {"start"=>"17/04/2017", "end"=>"18/04/2017"}, but it is for one day only (17th),
  # so had to do it as `.beginning_of_day - 1`
  def end_date
    params[:end].present? ? Time.zone.parse(params[:end]).beginning_of_day - 1 : nil
  end

  def start_date
    params[:start].present? ? Time.zone.parse(params[:start]).beginning_of_day : nil
  end

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end

  def coach
    @coach ||= company.coaches.find(params[:coach_id])
  end
end
