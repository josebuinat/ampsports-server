class Admin::CompanyController < Admin::BaseController
  def show
    company
  end

  def is_public
    # Fetch company outside of scopes, since we need this in Venue#edit page
    render json: { is_public: current_admin.company.can_be_listed_as_public? }
  end

  def update
    if perform_update
      render 'show'
    else
      render json: { errors: company.errors }, status: :unprocessable_entity
    end
  end

  # TODO: move to Admin::Company::QuickInvoicing controller
  def remove_user_from_quick_invoicing
    company.saved_invoice_users.delete(User.find(params[:user_id]))

    head :ok
  end

  private

  def perform_update
    company.assign_attributes update_params
    save_with_stripe = (update_params.keys & company.stripe_sensetive_fields.map(&:to_s)).any?
    if save_with_stripe
      company.save_with_stripe(current_admin, request.remote_ip)
    else
      company.save
    end
  end

  def company
    # explicit find to raise 404 error if no company
    @company ||= authorized_scope(Company).find(current_admin.company_id)
  end

  def create_params
    params.require(:company)
      .permit(
        :bank_name,
        :company_bic,
        :company_business_type,
        :company_city,
        :company_iban,
        :company_legal_name,
        :company_phone,
        :company_street_address,
        :company_tax_id,
        :company_website,
        :company_zip,
        :country_id,
        :invoice_sender_email,
        :tax_rate,
        :usa_routing_number,
        :usa_state,
        :copy_booking_mail_to,
        :coupon_code,
      )
  end

  def update_params
    create_params
  end
end
