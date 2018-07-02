class CompaniesController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_company, except: [:new, :create]

  authorize_resource

  def index
  end

  def show
    @resv_data = @company.charges_data('month') if @company.has_stripe?
    @venues = @company.venues
  end

  def customers
  end

  def invoices
  end

  def new
    @company = current_admin.build_company
    render layout: 'newlayout'
  end

  def reports
  end

  def create_report
    @transfers = current_company.transfers(params['report']['start_date'],
                                           params['report']['end_date'])
    render :report
  end

  def report
    @transfers = current_company.transfers(params['start'], params['end'])
    render :report, layout: false
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      current_admin.update_attribute(:company_id, @company.id)
      connector = StripeManaged.new(@company)
      begin
        account = connector.create_account!(current_admin,
                                            params[:tos] == 'on',
                                            request.remote_ip)
        if account
          flash[:notice] =
            "Managed Stripe account created! <a target='_blank' rel='platform-account' \
            href='https://dashboard.stripe.com/test/applications/users/#{account.id}'>View in dashboard &raquo;</a>"
        end
      rescue Stripe::StripeError
        flash[:error] = 'Unable to create Stripe account!'
      end
      redirect_to @company, notice: 'Saved...'
    else
      render :new, layout: 'empty'
    end
  end

  def edit
    @venues = @company.venues
  end

  def update
    if @company.update(company_params)
      redirect_to @company, notice: 'Updated...'
    else
      render :edit
    end
  end

  # post
  def import_customers
    @venue = Venue.find(params[:venue_id])

    importer = CSVImportUsers.new(params[:csv_file], @venue)
    @report = importer.run.report_message
    @failed_customers = importer.invalid_rows

    respond_to do |format|
      format.js
      format.html { redirect_to :back, notice: @report }
    end
  end

  def customers_csv_template
    send_data CSVImportUsers.csv_template, filename: "customers_csv_template.csv"
  end

  # qi = Quick Invoicing
  def remove_user_from_qi
    @company.saved_invoice_users.delete(User.find(params[:user_id]))
    redirect_to company_invoices_path(@company)
  end

  private

  def set_company
    @company = @current_company = current_admin.company
  end

  def company_params
    params.require(:company)
          .permit(
                  :active,
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
                  :usa_routing_number,
                  :usa_state
      )
  end

  def current_company
    @company
  end
end
