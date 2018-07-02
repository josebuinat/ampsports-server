class API::UsersController < API::BaseController
  include Imageable

  before_action :validate_confirmed_user, only: [:create]
  before_action :authenticate_request!, only: [:update, :destroy,
                                               :game_passes, :change_location,
                                               :upload_photo]

  def create
    user = User.new(create_params)
    if user.save
      SegmentAnalytics.user_registered(user)
      MailchimpWorker.add_user_to_list(user.email)
      render json: user.authentication_payload
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def email_check
    if params[:email].blank?
      render json: { message: I18n.t('api.users.email_check.email_required') }, status: :unprocessable_entity
    elsif User.find_by_email(params[:email]&.underscore)
      render json: { message: I18n.t('api.users.email_check.success') }, status: :ok
    else
      # Is rendered for both invalid Email Parameter and when no User is found
      render json: { message: I18n.t('api.users.email_check.error') }, status: :unprocessable_entity
    end
  end

  def confirm_account_email
    if confirmation_email_params[:email].blank?
      render json: { message: I18n.t('api.users.confirm_account.email_required') }, status: :unprocessable_entity
    elsif User.send_confirmation_instructions(confirmation_email_params)
      render json: { message: I18n.t('api.users.confirm_account.success') }, status: :ok
    else
      render json: { message: I18n.t('api.users.confirm_account.error') }, status: :unprocessable_entity
    end
  end

  def update
    updating_password = update_params[:password].present?
    # update_with_password will validate that current_password is correct
    # update_without_password will strip all passwords from the input
    method = updating_password ? :update_with_password : :update_without_password

    if current_user.public_send(method, update_params)
      i18n_path = updating_password ? 'api.users.password_updated' : 'api.users.profile_updated'
      render json: { user: current_user, message: I18n.t(i18n_path) }.merge(current_user.authentication_payload)
    else
      render json: { message: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    due_amount = current_user.reservations.map(&:outstanding_balance).sum
    if due_amount > 0
      render json: { message: I18n.t('api.users.errors.due_payment_delete') }, status: :unprocessable_entity
    else
      current_user.destroy
      render json: { message: I18n.t('api.users.user_deleted') }, status: :ok
    end
  end

  def game_pass_check
    user     = User.find(params[:user_id])
    venue    = Venue.find(params[:venue_id])
    @check   = user.has_game_pass?(venue)
    @charges = user.game_passes.where(venue_id:venue.id).first.try(:remaining_charges)
  end

  def game_passes
    @game_passes = @current_user.game_passes.includes(:venue)
  end

  def change_location
   if @current_user.update(location_params)
     render json: { msg: I18n.t('users.common.location_change_success') },
            status: :ok
   else
     render json: @current_user.errors, status: 422
   end
  end

  private

  def location_params
    params.require(:location).permit(:longitude, :latitude, :current_city)
  end

  def validate_confirmed_user
    email = params.dig(:user, :email)&.downcase
    user = User.find_by_email(email)
    return if user.nil?
    if user.not_able_to_login?
      # probably user tries to register the second time, guide him with activation resend instructions
      render json: { error: 'unconfirmed_account', message: I18n.t('api.users.not_confirmed') }, status: :unprocessable_entity
    # why user.unconfirmed?.. We don't say user already exist if it is confirmed?
    elsif user.encrypted_password.present? && user.unconfirmed?
      render json: { error: 'already_exists', message: I18n.t('api.users.already_exists') }, status: :unprocessable_entity
    end
  end

  def shared_params
    %i(city first_name image last_name password password_confirmation
       phone_number street_address stripe_id zipcode clock_type locale)
  end

  def create_params
    custom_params = %i(email default_country_id)
    user_params = params.require(:user).permit(*(shared_params + custom_params))
    user_params[:locale] = I18n.locale if user_params[:locale].blank?

    user_params.permit!
  end

  def update_params
    custom_params = %i(current_password)
    params.require(:user).permit(*(shared_params + custom_params))
  end

  def confirmation_email_params
    json_params_for(required: :user, permitted: [:email])
  end
end
