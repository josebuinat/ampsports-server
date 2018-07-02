# Handle admin devise account actions
class Admin::Auth::RegistrationsController < Admin::BaseController
  skip_before_action :authenticate_request!, only: [:create]

  def create
    admin = Admin.new(admin_create_params)
    company = Company.new(company_create_params)
    company.admins = [admin]

    Admin.transaction do
      raise ActiveRecord::Rollback if !admin.save || !company.save
    end

    if admin.persisted? && company.persisted?
      admin = Admin.authenticate(admin.email, admin_create_params[:password])
      render json: admin.authentication_payload, status: :created
    else
      errors = admin.errors.to_hash.merge(company.errors.to_hash)
      render json: { errors: errors}, status: :unprocessable_entity
    end
  end

  protected

  def admin_create_params
    params.require(:admin).permit(:password,
                                  :password_confirmation,
                                  :birth_date,
                                  :admin_ssn,
                                  :email,
                                  :first_name,
                                  :last_name).
                          merge(level: :god,
                                locale: I18n.locale)
  end

  def company_create_params
    params.require(:admin).permit(:company_legal_name, :coupon_code, :country_id)
  end
end
