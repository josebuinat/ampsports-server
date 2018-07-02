class Admin::Venues::SettingsController < Admin::BaseController
  before_action :reject_invalid_scope

  def index
    render json: { params[:scope].to_sym => settings.list }
  end

  private

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= authorized_scope(company.venues).find(params[:venue_id])
  end

  def settings
    venue.settings(params[:scope])
  end

  def reject_invalid_scope
    unless venue.class.has_settings?(params[:scope])
      return render json: { errors: [I18n.t('errors.settings.invalid_scope')] }, status: :unprocessable_entity
    end
  end
end
