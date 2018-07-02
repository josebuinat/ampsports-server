class Admin::Users::InvoicesController < Admin::BaseController

  def index
    @invoices = authorized_scope(user.invoices).where(company: company).viewable_by_user
  end

  private

  def user_id
    params[:user_id].presence
  end

  def company
    @current_company
  end

  def user
    @user ||= company.users.find(user_id)
  end

end
