class API::CustomersController < API::BaseController
  before_action :authenticate_admin!
  before_action :set_user, except: [:index, :create]
  before_action :reject_confirmed_user, only: [:update, :destroy]
  before_action :set_company
  before_action :set_and_connect_existing_customer, only: [:create, :update]
  before_action :reject_shared_user, only: [:destroy]

  # users and data for current company
  def index
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 10

    @customers = User.search(params[:search]).
                   where(id: @company.users).
                   order(sort_params).
                   page(params[:page]).
                   per_page(per_page)

    @outstanding_balances = @company.outstanding_balances
    @reservations = @company.user_reservations(@customers).group_by(&:user_id)
  end

  def show
    # outstanding balance and reservations for current company
    @outstanding_balance = @company.user_outstanding_balance(@customer)
    @lifetime_balance = @company.user_lifetime_balance(@customer)
    @reservations = @company.user_reservations(@customer)
  end

  def create
    if @existing_customer.present?
      @customer = @existing_customer

      return render 'show', status: 301
    end

    @customer = User.new(create_params)

    if @customer.save
      @company.venues.first.add_customer(@customer)

      render 'show', status: :ok
    else
      render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @existing_customer.present? && @existing_customer.id != @customer.id
      if @customer.has_only_company?(@company)
        @customer = @customer.replace_with_user(@existing_customer)
      else
        @customer = @existing_customer
      end

      return render 'show', status: 301
    end

    @customer.skip_reconfirmation!

    if @customer.update(update_params)
      head :ok
    else
      render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @customer.destroy
      head :ok
    else
      render json: { errors: [I18n.t('api.customers.cant_delete')] }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @customer = User.find_by_id(params[:id])

    if @customer.blank?
      render json: { errors: [I18n.t('api.customers.user_not_found')] }, status: 404
    end
  end

  def reject_confirmed_user
    if @customer.confirmed? || @customer.encrypted_password.present? || @customer.social_accounts.any?
      render json: { errors: [I18n.t('api.customers.already_confirmed')] }, status: :unprocessable_entity
    end
  end

  def set_company
    @company = current_admin.company

    unless @company.venues.count > 0
      render json: { errors: [I18n.t('api.customers.no_venue')] }, status: :unprocessable_entity
    end
  end

  def set_and_connect_existing_customer
    @existing_customer = User.where(email: params.dig(:customer, :email)&.downcase).take

    if @existing_customer.present?
      @company.venues.first.add_customer(@existing_customer)
    end
  end

  # can't delete if user has relation with other company
  def reject_shared_user
    unless @customer.has_only_company?(@company)
      render json: { errors: [I18n.t('api.customers.shared_user')] }, status: :unprocessable_entity
    end
  end

  def shared_params
    %i(first_name last_name email phone_number city street_address zipcode locale)
  end

  def create_params
    user_params = update_params
    user_params[:locale] = I18n.locale if user_params[:locale].blank?
    user_params.permit!
  end

  def update_params
    params.require(:customer).permit(*shared_params)
  end

  # returns hash {column_name: 'asc'}
  # params = {sort_by: '', sort_order: 'asc or desc'}
  def sort_params
    columns = case params[:sort_by]
      when 'full_name'
        [:first_name, :last_name]
      when 'email'
        [:email]
      when 'phone_number'
        [:phone_number]
      when 'address'
        [:city, :street_address]
      else
        [:created_at]
    end
    order = params[:sort_order].present? ? params[:sort_order] : 'asc'
    columns.product([order]).to_h
  end
end
