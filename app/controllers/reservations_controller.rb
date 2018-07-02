class ReservationsController < ApplicationController
  before_action :authenticate_admin!, except: [:index, :show, :refund, :resell]
  before_action :set_venue, except: [:index, :refund, :resell, :show_log]
  before_action :set_reservation, except: [:index, :new, :new_cart, :create, :show_log]
  around_action :use_timezone, except: [:index, :refund]

  # @OUTPUT
  def index
    @venue = Venue.includes(courts: :shared_courts).find(params[:venue_id])
    Time.use_zone(@venue.timezone) do
      if params[:start].present? && params[:end].present?
        start_date = TimeSanitizer.input(params[:start]).in_time_zone
        end_date = TimeSanitizer.input(params[:end]).in_time_zone
      end
      respond_to do |format|
        format.json do
          json = @venue.reservations_shared_courts_json(start_date, end_date)
          render json: json
        end
      end
    end
  end

  def new
    render layout: 'blank'
  end

  def new_cart
    render layout: 'blank'
  end

  # user refund
  def refund
    if @reservation.refundable? &&  @reservation.user == current_user
      @reservation.cancel(current_user)
      ActivityLog.record_log(:reservation_cancelled, @reservation.company.id, current_user, @reservation)
      message = 'Reservation refunded.'
    else
      message = 'Reservation can not be refunded.'
    end

    redirect_to :back, notice: message
  end

  # DUPLICATE, use API::ReservationsController::show instead
  def show
    calendar = Icalendar::Calendar.new
    calendar.add_event(@reservation.to_ics)

    respond_to do |format|
      format.html { render layout: 'blank' }
      format.ics { render text: calendar.to_ical }
    end
    # TODO: change this to render partial
  end

  # creation from admin
  def create
    create_reservation_owner
    saved, errors = {}, {}

    sanitized_bookings.each do |key, booking_params|
      reservation = Reservation.new(booking_params)
      if reservation.valid? && reservation.save
        saved[key] = reservation
        reservation.track_booking
        ActivityLog.record_log(:reservation_created, current_admin.company.id, current_admin, reservation)
      else
        errors[key] = reservation.errors.full_messages
      end
    end

    if errors.any?
      render json: { errors: errors, saved: saved }, status: :unprocessable_entity
    else
      render json: { saved: saved }, status: :ok
    end
  end

  def edit
    render layout: 'blank'
  end

  # update from admin
  def update
    @reservation.update_by_admin = true
    if @reservation.update(reservation_params)
      if params[:pay_reservation]
        if params[:pay_with_game_pass].present?
          @reservation.update(game_pass_id: params[:pay_with_game_pass])
        else
          @reservation.update(payment_type: :paid, amount_paid: @reservation.price)
        end
      end
      # dragging and resizing on calendar does not send price
      @reservation.recalculate_price_and_update! if reservation_params[:price] === nil
      ActivityLog.record_log(:reservation_updated, current_admin.company.id, current_admin, @reservation)
      head :ok
    else
      render json: { errors: { '0' => @reservation.errors.full_messages } }, status: :unprocessable_entity
    end
  end

  def make_copy
    @copy = Reservation.new(
                             user: @reservation.user,
                             price: @reservation.price,
                             note: @reservation.note,
                             payment_type: :unpaid,
                             booking_type: :admin
    )

    @copy.assign_attributes(move_reservation_params)

    if @copy.save
      ActivityLog.record_log(:reservation_created, current_admin.company.id, current_admin, @copy)
      head :ok
    else
      render json: { errors: { '0' => @copy.errors.full_messages } }, status: :unprocessable_entity
    end
  end

  def resell_to_user_form
    render layout: 'blank'
  end

  # sell resell from admin
  # takes params[:user] to find by id or create new user/guest
  def resell_to_user
    @reservation.update_by_admin = true
    create_reservation_owner

    if @reservation.resell_to_user(@owner)
      SegmentAnalytics.sold_resell_booking(@reservation, current_user || current_admin)
      ActivityLog.record_log(:reservation_updated, current_admin.company.id, current_admin, @reservation)
      head :ok
    else
      render json: { errors: { '0' => @reservation.errors.full_messages } }, status: :unprocessable_entity
    end
  end

  # cancel [, refund] from admin
  def destroy
    @reservation.cancel(current_admin)
    ActivityLog.record_log(:reservation_cancelled, current_admin.company.id, current_admin, @reservation)

    head :ok
  end

  def resell
    @reservation.update_by_admin = true if current_admin.present?

    if @reservation.resold?
      message = 'Reservation already resold.'
    elsif @reservation.reselling?
      @reservation.update(reselling: false)
      message = 'Reservation resell was withdrawn.'
      SegmentAnalytics.withdraw_resell_booking(@reservation, current_user || current_admin)
      ActivityLog.record_log(:reservation_updated, current_admin.company.id, current_admin, @reservation)
    elsif @reservation.resellable?
      @reservation.update(reselling: true)
      message = 'Reservation was put on resell.'

      if current_admin.present?
        SegmentAnalytics.admin_resell(@reservation, current_admin)
      else
        SegmentAnalytics.user_resell(@reservation, current_user)
      end
      ActivityLog.record_log(:reservation_updated, current_admin.company.id, current_admin, @reservation)
    end

    respond_to do |format|
      format.html { redirect_to :back, notice: message }
      format.js {
        render text: <<-JS
          resvFormSucc('#{message}')();
        JS
      }
    end
  end

  def show_log
    @reservation = Reservation.unscoped.find(params[:id])

    @court_names = @reservation.logged_courts.each_with_object({}) do |court, hash|
      hash[court.id] = "#{court.court_name} (#{court.sport})"
    end

    render :show_log, layout: 'blank'
  end

  private

  def create_reservation_owner
    if params[:guest]
      @owner = Guest.create(full_name: params[:guest][:full_name])
    else
      @owner = User.find_or_create_by_email(params[:user], @venue)
      if @owner.persisted?
        @venue.users << @owner unless @venue.users.include?(@owner)
      end
    end

    @owner
  end

  def reservation_params
    reservation_params = params.require(:reservation)
                               .permit(:start_time,
                                       :end_time,
                                       :price,
                                       :court_id,
                                       :user_id,
                                       :date,
                                       :amount_paid,
                                       :note)
    reservation_params[:start_time] = TimeSanitizer.input("#{reservation_params[:date]} #{reservation_params[:start_time]}")
    reservation_params[:end_time] = TimeSanitizer.input("#{reservation_params[:date]} #{reservation_params[:end_time]}")
    reservation_params
  end

  def move_reservation_params
    reservation_params.extract!(:start_time, :end_time, :court_id)
  end

  def sanitized_bookings
    params[:reservations].map do |k, r|
      [k, {
            start_time:    TimeSanitizer.input("#{r[:date]} #{r[:start_time]}"),
            end_time:      TimeSanitizer.input("#{r[:date]} #{r[:end_time]}"),
            court_id:      r[:court_id].to_i,
            price:         r[:price].to_f,
            user:          @owner,
            note:          params[:reservation][:note].to_s,
            payment_type: :unpaid,
            booking_type: :admin,
          }]
    end.to_h
  end

  def set_venue
    @venue = Venue.find(params[:venue_id])
  end

  def use_timezone
    venue = @venue
    unless venue.present?
      reservation = @reservation || Reservation.unscoped.find(params[:id])
      venue = reservation.venue
    end

    Time.use_zone(venue.timezone) { yield }
  end

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end
end
