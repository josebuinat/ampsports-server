class Admin::Auth::SessionsController < ::Devise::SessionsController
  respond_to :json

  def create
    admin = Admin.authenticate(params[:email], params[:password])
    coach = Coach.authenticate(params[:email], params[:password])
    user = admin || coach

    if user
      render json: user.authentication_payload
    else
      render json: { errors: [I18n.t('api.authentication.wrong_password')] }, status: :unauthorized
    end
  end
end
