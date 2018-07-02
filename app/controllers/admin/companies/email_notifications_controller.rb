class Admin::Companies::EmailNotificationsController < Admin::BaseController
  def index
    authorize company, :read_email_notifications_settings?
    render json: settings.list
  end

  def update_many
    authorize company, :edit_email_notifications_settings?
    update_params.each_pair do |key, value|
      if settings.has? key
        settings.put key, !!value
      end
    end

    head :ok
  end

  private

  def update_params
    params.require(:company_email_notification)
  end

  def company
    @company ||= current_admin.company
  end

  def settings
    company.settings(:email_notifications)
  end
end
