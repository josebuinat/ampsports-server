class API::AuthController < API::BaseController
  before_action :validate_confirmed_user, only: [:authenticate]
  before_action :authenticate_request!, only: [:renew_token]

  def authenticate
    user = User.authenticate(params[:email], params[:password])

    if user
      render json: user.authentication_payload
    else
      messages = [I18n.t('api.authentication.wrong_password')]
      if existing_user && @existing_user.social_accounts.any?
        messages.push I18n.t('api.authentication.try_social_signin')
      end
      
      render json: { errors: messages }, status: :unauthorized
    end
  end

  def renew_token
    render json: current_user.authentication_payload
  end

  private

  def validate_confirmed_user
    if existing_user&.not_able_to_login?
      render json: { error: 'unconfirmed_account', message: I18n.t('api.users.not_confirmed') }, status: :unprocessable_entity
    end
  end

  def existing_user
    @existing_user ||= User.find_by(email: params[:email]&.downcase)
  end

end
