class API::CompaniesController < API::BaseController

  def send_support_email
    SupportMailer.support_email(params[:title], params[:content], current_admin.email, current_admin.company.company_legal_name).deliver!
    head :ok
  end

  def customers
    customers = Company.find(params[:company_id]).users.select(:id, :email, :first_name, :last_name)
                       .map { |c| {label: "#{c.full_name} #{c.email}", value: c.id} }
    render json: customers
  end
end
