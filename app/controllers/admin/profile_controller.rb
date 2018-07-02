class Admin::ProfileController < Admin::BaseController

  def update
    updating_password = password_fields.any? { |x| update_params[x].present? }
    updating_only_locale = update_params.keys == ['locale']
    # update_with_password will validate that current_password is correct
    # update_without_password will strip all passwords from the input
    # update_without_validations will update model without... validations & callbacks
    method = if updating_password
      :update_with_password
    elsif updating_only_locale
      :update_without_validations
    else
      :update_without_password
    end

    if current_admin.public_send(method, update_params)
      render 'show'
    else
      render json: { errors: current_admin.errors }, status: :unprocessable_entity
    end
  end

  private

  def password_fields
    %i(current_password password password_confirmation)
  end

  def update_params
    regular_fields = %i(first_name last_name email admin_ssn clock_type locale)
    params.require(:admin).permit(regular_fields + password_fields).tap do |x|
      password_fields.each { |field| x.delete(field) if x[field].blank? }
    end
  end
end
