class InvoicesController < ApplicationController
  before_action :set_company
  before_action :set_invoice, only: [:update]
  around_action :use_timezone, only: [:show, :create_drafts, :print_all, :create_report]

  def index
    @invoices = @company.invoices.includes(:owner).components_includes
    @mode = params[:mode]
    case @mode
    when 'unpaid'
      @invoices = @invoices.unpaid
    when 'paid'
      @invoices = @invoices.paid
    else
      @mode = 'drafts'
      @invoices = @invoices.drafts
    end

    ob = OutstandingBalances.new(@company)
    @outstanding_balances = ob.outstanding_balances
    @users = ob.all_users
    @membership_users = ob.membership_users
    @recent_users = ob.recent_users
    @saved_users = ob.saved_users
  end

  def create
    invoice = Company.find(params[:company_id]).invoices.
      build(owner_id: params[:invoice][:user_id], owner_type: 'User')
    params[:invoice][:custom_invoice_components].each do |cic|
      invoice.custom_invoice_components.build(name: cic[:name],
                                              vat_decimal: cic[:vat].to_f,
                                              price: cic[:price].to_f)
    end
    begin
      Invoice.transaction do
        invoice.save!
        invoice.custom_invoice_components.each(&:save!)
      end
      render nothing: true, status: :ok
    rescue StandardError
      render nothing: true, status: 400
    end
  end

  def create_drafts
    @users = User.where(id: get_user_ids)
    @custom_biller = GroupCustomBiller.find_by_id(params[:custom_biller_id])

    redirect_to(:back, notice: "Please select some users") and return if @users.empty?

    cache_params
    @invoices = {} # user_id => invoice
    from = TimeSanitizer.input(invoice_drafts_params[:start_date]).in_time_zone.beginning_of_day.utc
    to = TimeSanitizer.input(invoice_drafts_params[:end_date]).in_time_zone.end_of_day.utc

    @users.each do |user|
      invoice = Invoice.create_for_company(@company, user, from: from,
                                                           to: to,
                                                           custom_biller: @custom_biller)

      @invoices[user.id] = invoice if invoice.present?
    end

    if @invoices.keys.empty?
      redirect_to :back, notice: "There's nothing to invoice for this period."
    else
      redirect_to company_invoices_path(@company), notice: "#{@invoices.keys.size} invoices were generated successfully. Now review and send them."
    end
  end

  def send_all
    params[:selected_ids].each do |id|
      @company.invoices.find(id).send!(params[:due_date])
    end
    ActivityLog.record_log(:invoices_sent, @company.id, current_admin, @company.invoices.where(id: params[:selected_ids]))
    redirect_to company_invoices_path(@company),
      notice: "#{params[:selected_ids].size} invoices were sent out successfully"
  end

  def print_all
    @invoices = @company.invoices.
                         includes(:owner, :group_custom_biller, :company).
                         components_includes.
                         where(id: params[:selected_ids])
  end

  def unsend_all
    params[:selected_ids].each { |id| Invoice.find(id).undo_send! }
    redirect_to company_invoices_path(@company),
      notice: t('.undo_success', invoice_count: params[:selected_ids].size)
  end

  def mark_paid
    count = Invoice.mark_paid(params[:selected_ids])
    redirect_to company_invoices_path(@company),
      notice:  t('.success', count: count)
  end

  def destroy_all
    params[:selected_ids].each do |id|
      @company.invoices.find(id).destroy
    end
    redirect_to company_invoices_path(@company, mode: 'unpaid'),
      notice: "#{params[:selected_ids].size} invoices were deleted successfully"
  end

  def update
    @invoice.assign_attributes(invoice_params)
    if @invoice.save
      render json: {status: 'updated', invoice: { total: @invoice.total }}
    else
      render json: {error: 'validation error'}
    end
  end

  def show
    @invoice = Invoice.components_includes.find(params[:id])
  end

  def create_report
    from = TimeSanitizer.input(TimeSanitizer.output(report_params[:from]).beginning_of_day.to_s)
    to = TimeSanitizer.input(TimeSanitizer.output(report_params[:to]).end_of_day.to_s)
    report = Excel::InvoiceReport.new(current_admin).generate(from, to)
    send_data report.to_stream.read, filename: report.filename
  end

  protected

  def cache_params
    @company.update(cached_invoice_period_start: invoice_drafts_params[:start_date],
                    cached_invoice_period_end: invoice_drafts_params[:end_date])
    return unless invoice_drafts_params[:user_ids]
    users = User.find(invoice_drafts_params[:user_ids])
    @company.update(recent_invoice_users: users)
    @company.saved_invoice_users << users && @company.save if params[:save]
  end

  def set_company
    if current_admin.try(:company)
      @company = current_admin.company
    elsif Company.find(params[:company_id])
      @company = Company.find(params[:company_id])
    end
  end

  def use_timezone
    Time.use_zone(@company.venues.first&.timezone || Time.zone) { yield }
  end

  def set_invoice
    @invoice = @company.invoices.find(params[:id])
  end

  def invoice_params
    params.require('invoice').permit(:total)
  end

  def invoice_drafts_params
    params.permit(:start_date, :end_date, :user_type, :user_ids => [])
  end

  def report_params
    params.require(:report).permit(:from, :to)
  end

  def get_user_ids
    user_type = invoice_drafts_params[:user_type]
    if user_type
      ob = OutstandingBalances.new(@company)
        users = case user_type
                when "membership_users"
                  ob.membership_users
                when "saved_users"
                  ob.saved_users
                when "all_users"
                  ob.all_users
                end
      users.map(&:id)
    else
      invoice_drafts_params[:user_ids]
    end
  end
end
