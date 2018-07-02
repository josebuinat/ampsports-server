class Admin::UsersController < Admin::BaseController
  before_action :reject_confirmed_user, only: [:update, :destroy]
  before_action :reject_shared_user, only: [:destroy]
  before_action :reject_user_with_upcoming_reservations, only: [:destroy]

  def index
    ob = OutstandingBalances.new(company, custom_biller)

    if params[:with_outstanding_balance].present?
      @users = ob.users_by_type(params[:user_type] || 'all_users')
    else
      @users = company.users
    end

    @users = authorized_scope(@users).search(params[:search])
    @users = @users.sort_on(params[:sort_on], company: company) if params[:sort_on]
    @users = @users.paginate(page: params[:page], per_page: per_page)

    @outstanding_balances = params[:light] ? {} : ob.outstanding_balances
    @lifetime_values = params[:light] ? {} : company.lifetime_balances(@users.map(&:id))
    venue
  end

  def show
    user
    venue
  end

  def create
    @venue = company.venues.first
    if @venue.nil?
      render json: { errors: { base: 'Create a venue first' }}, status: :unprocessable_entity
      return
    end

    if find_existing_user
      connect_existing_user_to_company
      @user = @existing_user
    else
      # cannot use venue.users.build here, as it would not associate it with the venue
      @user =authorize @venue.users.create(create_params)
      SegmentAnalytics.admin_created_user(@user, current_admin) if @user.persisted?
    end

    if @user.persisted?
      render 'show', status: :created
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end

  def update
    if find_existing_user && @existing_user.id != user.id
      connect_existing_user_to_company
      # if incorrect user is deletable, replace it with existing
      if user.has_only_company?(company)
        @existing_user = user.replace_with_user(@existing_user)
      end
      @user = @existing_user
    end

    # do not send additional confirmation on any update
    user.skip_reconfirmation!
    if user.update(update_params)
      render 'show'
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if user.destroy
      render json: [user.id]
    else
      render json: { errors: [I18n.t('api.customers.cant_delete')] }, status: :unprocessable_entity
    end
  end

  def select_options
    @users = authorized_scope(company.users)
    @users = @users.search(params[:search]) if params[:search]
    options = @users.map do |user|
      { value: user.id, label: user.full_name }
    end
    render json: options
  end

  private

  def reject_confirmed_user
    if user.activated?
      render json: { errors: [I18n.t('api.customers.already_confirmed')] }, status: :unprocessable_entity
    end
  end

  def reject_user_with_upcoming_reservations
    if user.reservations.future.any?
      render json: { errors: [I18n.t('api.customers.has_future_reservations')] }, status: :unprocessable_entity
    end
  end

  # can't delete if user has relation with other company
  def reject_shared_user
    unless user.has_only_company?(company)
      render json: { errors: [I18n.t('api.customers.shared_user')] }, status: :unprocessable_entity
    end
  end

  def find_existing_user
    @existing_user = authorized_scope(User.where(email: params.dig(:user, :email)&.downcase), :update).take
  end

  def connect_existing_user_to_company
    company.venues.first.add_customer(@existing_user)
  end

  def update_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone_number, :city,
      :street_address, :zipcode, :clock_type, :locale, :additional_phone_number, :note,
    )
  end

  def create_params
    user_attributes = update_params
    user_attributes[:locale] = I18n.locale if user_attributes[:locale].blank?
    user_attributes
  end

  def per_page
    params[:per_page].to_i > 0 ? params[:per_page].to_i : 10
  end

  def user
    @user ||= authorized_scope(company.users).find(params[:id])
  end

  def company
    @company ||= current_admin.company
  end

  # optional for :index, :show
  def venue
    @venue ||= params[:venue_id] && company.venues.find(params[:venue_id])
  end

  # optional for :index
  def custom_biller
    @custom_biller ||= params[:custom_biller_id] && company.group_custom_billers.
                                                          find(params[:custom_biller_id])
  end
end
