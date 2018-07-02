class API::Users::SettingsController < API::BaseController
  before_action :authenticate_request!
  before_action :reject_invalid_scope

  def index
    render json: { params[:scope].to_sym => settings.list }
  end

  def update
    unless settings.has?(params[:name])
      return render json: { errors: [I18n.t('errors.settings.invalid_name')] }, status: :not_found
    end

    if settings.put(params[:name], params[:value])
      render json: { params[:scope].to_sym => settings.list }
    else
      render json: { errors: [I18n.t('errors.settings.update_failed')] }, status: :unprocessable_entity
    end
  end

  private

  def settings
    current_user.settings(params[:scope])
  end

  def reject_invalid_scope
    unless current_user.class.has_settings?(params[:scope])
      return render json: { errors: [I18n.t('errors.settings.invalid_scope')] }, status: :unprocessable_entity
    end
  end
end
