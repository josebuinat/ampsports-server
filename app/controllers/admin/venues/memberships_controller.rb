class Admin::Venues::MembershipsController < Admin::BaseController
  around_action :use_timezone
  around_action :wrap_in_transaction, only: [:create, :update]

  def index
    @memberships = authorized_scope(memberships).includes(:user, :courts)
    @memberships = @memberships.search(params[:search]) if params[:search].present?
    @memberships = @memberships.sort_on(params[:sort_on]) if params[:sort_on].present?
    @memberships = @memberships.paginate(page: params[:page])
    @reservations = Reservation.reservations_for_memberships(@memberships.map(&:id))
  end

  def show
    membership
  end

  def create
    @membership = authorize venue.memberships.build(create_params)
    membership.make_reservations(time_params, court_ids) if membership.valid?

    if membership.valid? && membership.save
      # user was created
      if params.dig(:membership, :user, :first_name).present?
        SegmentAnalytics.admin_created_user(membership.user, current_admin)
      end
      # hard to do that from create_params, as it could be both user_id OR user_attributes
      @venue.add_customer(@membership.user, track_with_actor: current_admin)
      ActivityLog.record_log(:membership_created, company.id, current_admin, membership)

      render 'show', status: :created
    else
      render 'errors', status: :unprocessable_entity
    end
  end

  def update
    membership.ignore_overlapping_reservations = true if params.dig(:membership, :ignore_overlapping_reservations)
    if membership.handle_update(params[:membership], time_params, court_ids)
      ActivityLog.record_log(:membership_updated, company.id, current_admin, membership)
      render 'show'
    else
      render 'errors', status: :unprocessable_entity
    end
  end

  def destroy
    membership.handle_destroy
    ActivityLog.record_log(:membership_cancelled, company.id, current_admin, membership)
    render json: [membership.id]
  end

  def destroy_many
    deleted_memberships = many_memberships.select do |membership|
      membership.handle_destroy
    end
    ActivityLog.record_log(:membership_cancelled, company.id, current_admin, deleted_memberships)

    render json: deleted_memberships.map(&:id)
  end

  def import
    authorize Membership

    @importer = CSVImportMemberships.new(params[:csv_file], venue, params[:ignore_conflicts]).run

    if @importer.valid?
      render status: :created
    else
      render json: { errors: @importer.errors }, status: :unprocessable_entity
    end
  end

  def renew_many
    # taking memberships we are interested in and try to process them all
    new_memberships = memberships.where(id: params[:membership_ids]).map do |membership|
      last_reservation = membership.reservations.last
      static_attributes = membership.attributes.symbolize_keys!.except!(:id)
      start_tact = TimeSanitizer.output(last_reservation.start_time).strftime('%H:%M')
      end_tact = TimeSanitizer.output(last_reservation.end_time).strftime('%H:%M')

      membership_params = static_attributes.merge(
        start_time: TimeSanitizer.input("#{params[:start_date]} #{start_tact}"),
        end_time: TimeSanitizer.input("#{params[:end_date]} #{end_tact}"),
        ignore_overlapping_reservations: params[:ignore_overlapping_reservations],
        assigned_court_ids: membership.court_ids,
      )

      time_params = MembershipTimeSanitizer.new(
        membership_params.merge(
          weekday: last_reservation.start_time.strftime('%A').downcase,
          start_date: params[:start_date],
          end_date: params[:end_date],
          start_time: start_tact,
          end_time: end_tact,
        )
      ).time_params

      # return tuple of Membership instance and time params
      [memberships.build(membership_params), time_params]
    end

    @updated, @failed = new_memberships.partition do |tuple|
      membership, time_params = tuple
      if membership.valid?
        membership.make_reservations(time_params, membership.assigned_court_ids)
        membership.save
      else
        false
      end
    end

    @updated.map!(&:first)
    @failed.map!(&:first)

    if @failed.empty?
      head :ok
    else
      render status: :unprocessable_entity
    end
  end

  private

  def court_ids
    if params.dig(:membership, :use_all_courts)
      return venue.court_ids
    end
    params.dig(:membership, :court_ids)
  end

  def create_params
    membership_permitted_attributes = %i(title price note ignore_overlapping_reservations)
    coach_ids = params.require(:membership).permit(coach_ids: [])[:coach_ids]
    params.require(:membership).permit(*membership_permitted_attributes).merge({
        start_time: time_params[:membership_start_time],
        end_time: time_params[:membership_end_time],
        venue_id: venue.id,
        user: membership_owner,
        coach_ids: coach_ids,
    }).permit!
  end

  def membership_owner
    group_id = params.dig(:membership, :group_id)
    user_id = params.dig(:membership, :user_id)
    owner = if group_id
              Group.find(group_id)
            elsif user_id
              User.find(user_id)
            else # maybe we already have 'new' user in the system
              User.find_by(email: params.dig(:membership, :user, :email))
            end

    unless owner.present?
      user_permitted_attributes = [:first_name, :last_name, :email, :street_address, :zipcode, :city, :phone_number, :locale]
      user_attributes = params.require(:membership).permit(user: user_permitted_attributes)[:user]
      user_attributes[:locale] = I18n.locale if user_attributes && user_attributes[:locale].blank?
      owner = User.new(user_attributes)
    end

    owner
  end

  def time_params
    @time_params ||= MembershipTimeSanitizer.new(params[:membership]).time_params
  end

  def membership
    @membership ||= memberships.find(params[:id])
  end

  def memberships
    @memberships ||= authorized_scope(venue.memberships)
  end

  def many_memberships
    @many_memberships ||= memberships.where(id: params[:membership_ids])
  end

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= company.venues.find(params[:venue_id])
  end
end
