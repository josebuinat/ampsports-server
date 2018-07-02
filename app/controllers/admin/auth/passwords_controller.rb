class Admin::Auth::PasswordsController < ::Devise::PasswordsController
  respond_to :json

  def update
    # renders a .json builder template with auth-token
    super
  end

  private

  def resource_class
    email = resource_params[:email]
    if email.present?
      guess_class_by_email email
    else
      guess_class_by_token resource_params[:reset_password_token]
    end
  end

  def guess_class_by_email(email)
    Admin.exists?(email: email) ? Admin : Coach
  end

  def guess_class_by_token(original_token)
    reset_password_token = Devise.token_generator.digest(self, :reset_password_token, original_token)
    Admin.exists?(reset_password_token: reset_password_token) ? Admin : Coach
  end

  def resource_params
    params.fetch(:admin, params)
  end

end
