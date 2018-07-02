module MailersHelper
  def user_frontend_host
    ENV['USER_FRONTEND_HOST']
  end

  def admin_frontend_host
    ENV['ADMIN_FRONTEND_HOST']
  end

  def api_host
    ENV['API_HOST']
  end

  def get_confirmation_url(resource, token)
    confirmation_url(resource,
                     confirmation_token: token,
                     needs_to_setup_password: !resource.has_password?,
                     host: resource.is_a?(User) ? user_frontend_host : admin_frontend_host,
                     # users to user frontend, and admins with coaches to admin frontend
                     resource: resource.class.name )
  end

  # returns url for react app 'set new password' page
  def reset_password_url(resource, token)
    "#{react_root_url(resource)}/password/edit?reset_password_token=#{token}&resource=#{resource.class.name}"
  end

  # returns host url depending on resource type
  def react_root_url(resource)
    if resource.is_a?(User)
      user_frontend_host
    else
      # admins and coaches to admin frontend
      admin_frontend_host
    end
  end
end
