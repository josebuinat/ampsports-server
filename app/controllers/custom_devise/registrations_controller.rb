# Handle user devise account actions
class CustomDevise::RegistrationsController < Devise::RegistrationsController
 def create
   super
   flash[:segment_alias] = resource.id
   flash[:segment_identify] = resource.segment_params
  end

 # Todo: delete this (and corresponding route) when frontend changes to react-only
 def update_password
   @user = current_user
   if @user.update_with_password(user_params)
     # Sign in the user by passing validation in case their password changed
     sign_in :user, @user, bypass: true
     flash[:notice] = 'Password updated successfully'
   end
   render 'edit'
 end

  protected

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  def after_sign_up_path_for(resource)
    signed_in_root_path(resource)
    if resource.is_a?(Admin)
      new_company_path
    else
      root_path
    end
  end

  def user_params
    params.require(:user).permit(:password,
                                 :password_confirmation,
                                 :current_password)
  end
end
