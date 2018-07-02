class MembershipsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_venue, except: [:csv_template]
  before_action :set_membership, only: [:show, :update, :convert_to_cc]
  around_action :use_timezone, except: [:csv_template]

  def index
    @memberships = @venue.memberships
    respond_to do |format|
      format.json do
        json = @memberships.map do |membership|
          {
            start: membership.start_time,
            end: membership.end_time,
            user: membership.user_id,
            venue: membership.venue_id
          }
        end
        render json: json
      end
    end
  end

  def show
  end

  def create
    time_params = MembershipTimeSanitizer.new(params[:membership]).time_params
    user = User.find_or_create_by_email(params[:user], @venue)

    membership = Membership.new(membership_params)
    membership.user = user
    membership.venue_id = params[:venue_id]
    membership.start_time = time_params[:membership_start_time]
    membership.end_time = time_params[:membership_end_time]
    membership.ignore_overlapping_reservations = !!params[:ignore_overlapping_reservations]

    membership.make_reservations(time_params, params[:court_ids]) if membership.valid?
    begin
      Membership.transaction do
        user.save!
        membership.save!
        unless @venue.users.include?(user)
          VenueUserConnector.create user: user, venue: @venue
        end
      end
      ActivityLog.record_log(:membership_created, @venue.company.id, current_admin, membership)
      redirect_to memberships_path(@venue), notice: 'Created Membership...'
    rescue
      handle_overlapping_reservations(membership, prev_params)
      flash[:alert] = 'Membership could not be created'
      render template: 'venues/memberships'
    end
  end

  def update
    time_params = MembershipTimeSanitizer.new(params[:membership]).time_params
    @membership.ignore_overlapping_reservations = !!params[:ignore_overlapping_reservations]
    if @membership.handle_update(params[:membership], time_params, params[:court_ids])
      ActivityLog.record_log(:membership_updated, @venue.company.id, current_admin, @membership)
      redirect_to memberships_path(@venue), notice: 'Updated Membership...'
    else
      handle_overlapping_reservations(@membership, prev_params)

      flash[:alert] = @membership.errors.map { |_, msg| msg.humanize }.first ||
                      I18n.t('activerecord.errors.models.membership.update_failure')
      render template: 'venues/memberships'
    end
  end

  def destroy
    @membership = Membership.find(params[:id])
    @membership.handle_destroy
    ActivityLog.record_log(:membership_cancelled, @venue.company.id, current_admin, @membership)
    redirect_to :back, notice: 'Membership deleted'
  rescue ActiveRecord::RecordNotFound
    redirect_to :back, alert: 'Membership not found!'
  end

  def import
    importer = CSVImportMemberships.new(params[:csv_file], @venue, params[:ignore_conflicts]).run
    @report_message = importer.report_message
    @failed_rows = importer.invalid_rows

    respond_to do |format|
      format.js
      format.html { redirect_to :back, notice: @report_message }
    end
  end

  def csv_template
    send_data CSVImportMemberships.csv_template, filename: "memberships_csv_template.csv"
  end

  private

  def prev_params
    params.permit(:venue_id,
                  :controller,
                  :action,
                  user: [:user_id],
                  membership: [
                    :start_time, :end_time, :start_date, :end_date,
                    :user_id, :venue_id, :price, :title, :note
                  ],
                  :court_ids => [])
  end

  def membership_params
    params.require(:membership).permit(:start_time, :end_time, :user_id, :venue_id, :price, :title, :note)
  end

  def set_venue
    @venue = Venue.find(params[:venue_id])
  end

  def set_membership
    @membership = Membership.find(params[:id])
  end

  def use_timezone
    Time.use_zone(@venue.timezone) { yield }
  end

  def handle_overlapping_reservations(membership, prev_params)
    @ignore_overlaps_url = url_for(prev_params.merge({ignore_overlapping_reservations: true}))
    @bad_reservations = membership.reservations.reject(&:valid?)
    @memberships = membership.venue.memberships.includes(:user)
    @reservations = Reservation.reservations_for_memberships(@memberships.map(&:id))
  end
end
