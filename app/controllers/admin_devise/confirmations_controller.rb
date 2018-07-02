class AdminDevise::ConfirmationsController < Devise::ConfirmationsController
  # following the example from manual:
  # slightly re-adjust it, as it is out of date and does not accommodate all our needs
  # https://github.com/plataformatec/devise/wiki/How-To:-Override-confirmations-so-users-can-pick-their-own-passwords-as-part-of-confirmation-activation

  def show
    self.resource = resource_class.find_or_initialize_with_error_by(:confirmation_token, params[:confirmation_token])

    if resource.errors.empty? && resource.has_password? && resource.confirmed?
      set_flash_message(:notice, :confirmed) if is_flashing_format?
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    end
  end

  # PUT /resource/confirmation
  def update
    with_unconfirmed_confirmable do
      unless @confirmable.has_password?
        permitted_params = params.require(params_key).permit(:password, :password_confirmation)
        if @confirmable.update_attributes(permitted_params)
          return do_confirm
        end
      else
        @confirmable.errors.add(:email, :password_already_set)
      end
    end

    do_show
  end

  protected

  def with_unconfirmed_confirmable
    @confirmable = resource_class.find_or_initialize_with_error_by(:confirmation_token, confirmation_token_from_params)
    if !@confirmable.new_record? && !@confirmable.confirmed?
      yield
    end
  end

  def do_show
    self.resource = @confirmable
    render 'devise/confirmations/show'
  end

  def do_confirm
    @confirmable.confirm
    set_flash_message :notice, :confirmed
    sign_in_and_redirect(resource_name, @confirmable)
  end

  private
  helper_method :confirmation_token_from_params

  def confirmation_token_from_params
    params[:confirmation_token] || params.dig(params_key, :confirmation_token)
  end

  def params_key
    resource_class.to_s.underscore
  end

end
