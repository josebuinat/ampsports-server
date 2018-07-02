class CustomDevise::PasswordsController < Devise::PasswordsController
  respond_to :json
  # Partial copy-paste from API::BaseController.
  # Delete it & inherit all Devise controllers from API::BaseController
  # When everything will work on react (hence API-only)
  protect_from_forgery with: :null_session
  before_action :set_json_if_xhr

  def update
    # quick note: this thing renders a .json builder template with auth-token
    super
  end

  private

  def set_json_if_xhr
    # Note: request.xhr? will give us wrong result, have to compare content_type
    if request.env['action_dispatch.request.content_type']&.json?
      request.format = :json
    end
  end
end