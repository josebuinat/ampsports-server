class Admin::Auth::ConfirmationsController < Devise::ConfirmationsController
  protect_from_forgery with: :null_session
  before_action { request.format = :json }
  respond_to :json

  def show
    Admin.transaction do
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])

      if resource.confirmed? && !resource.has_password?
        passwords = { password: params[:password], password_confirmation: params[:password_confirmation] }
        raise ActiveRecord::Rollback unless resource.update(passwords)
      end
    end

    resource.clean_up_passwords

    if resource.errors.present?
      render json: { errors: resource.errors }, status: :unprocessable_entity
    end
  end

  private

  def resource_class
    Admin.exists?(confirmation_token: params[:confirmation_token]) ? Admin : Coach
  end
end
