class CustomDevise::ConfirmationsController < Devise::ConfirmationsController
  protect_from_forgery with: :null_session
  before_action :set_default_response_format
  respond_to :json

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.persisted? && !resource.has_password?
      resource.update(password: params[:password],
                      password_confirmation: params[:password_confirmation])
      resource.clean_up_passwords
    end

    MailchimpWorker.add_user_to_list(resource.email) if resource.is_a? User

    # devise goes crazy with the default view for json on errors, so we have to manually
    # render this case
    if resource.errors.present?
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end

  end

  private

  def permitted_params
    params.require(resource_name).permit(:confirmation_token,
                                         :password,
                                         :password_confirmation)
  end

  def set_default_response_format
    request.format = :json
  end
end
