class CustomDevise::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Basically due to different domains we manually do CSRF. When we set up a
  # reverse proxy and go with one domain we will be able to bring this
  # security checks back.
  # related: provider_ignores_state: true on devise.rb initialize
  skip_before_action :verify_authenticity_token
  skip_before_action :verify_same_origin_request

  def facebook
    error, @user = SocialLoginService.from_omniauth(request.env["omniauth.auth"])

    if error.nil?
      sign_in @user
      render json: @user.authentication_payload
    else
      error_for_frontend = {
        error: error,
        email: @user.email,
        id: @user.id,
        message: I18n.t("api.authentication.#{error}")
      }
      render json: error_for_frontend, status: :unprocessable_entity
    end
  end

end
