class Admin::InvoicesController < Admin::BaseController
  # as we respond in PDF there
  skip_before_action :set_default_response_format, only: [:print_all]
  around_action :use_timezone

  def index
    @invoices = authorized_scope(company.invoices).includes(:owner)

    @invoices = @invoices.public_send(policy(Invoice).authorized_type_scope(params[:type]))
    @invoices = @invoices.search(params[:search]) if params[:search]
    @invoices = @invoices.sort_on(params[:sort_on]) if params[:sort_on]
    @invoices = @invoices.paginate(page: params[:page], per_page: per_page)
  end

  # currently for custom invoices only
  def create
    @invoice = authorize company.invoices.build(create_params)
    if @invoice.save
      render 'show', status: :created
    else
      render json: { errors: @invoice.errors }, status: :unprocessable_entity
    end
  end

  def show
    @invoice = authorized_scope(company.invoices).components_includes.find(params[:id])
  end

  def update
    if invoice.update(update_params)
      render 'show'
    else
      render json: { errors: invoice.errors }, status: :unprocessable_entity
    end
  end

  def destroy_many
    deleted = many_invoices.select do |invoice|
      invoice.destroy
    end

    render json: deleted.map(&:id)
  end

  def create_drafts
    authorize Invoice
    # TODO: would be nice to extract this into a service
    status, message = catch(:message) do
      users = users_to_invoice.to_a
      throw(:message, [:error, I18n.t('invoices.create_invoices.no_users_selected')]) if users.empty?

      created_for_users = users.select do |user|
        if user.is_a?(User)
          Invoice.create_for_company(company, user, from: sanitized_start_date,
                                                    to: sanitized_end_date,
                                                    custom_biller: custom_biller)
        elsif user.is_a?(Coach)
          Invoice.create_for_coach(user, from: sanitized_start_date, to: sanitized_end_date)
        end
      end.compact

      if created_for_users.empty?
        throw :message, [:error, I18n.t('invoices.create_invoices.nothing_to_invoice')]
      else
        save_to_quick_invoicing(created_for_users)
        throw :message, [:success, I18n.t('invoices.create_invoices.success', count: created_for_users.size)]
      end
    end

    if status == :success
      render json: { message: message }, status: :created
    else
      render json: { message: message }, status: :unprocessable_entity
    end
  end

  def send_all
    sent_invoices = many_invoices.select do |invoice|
      invoice.send!(params[:due_date], sender_email(invoice))
    end

    if sent_invoices.present?
      ActivityLog.record_log(:invoices_sent, company.id, current_admin, sent_invoices)
    end

    render json: { message: I18n.t('invoices.send_all.success', count: sent_invoices.size) }
  end

  def print_all
    @invoices = authorized_scope(company.invoices).
                        includes(:owner, :group_custom_biller, :company).
                        components_includes.
                        where(send_all_params)
  end

  def unsend_all
    unsent = many_invoices.select do |invoice|
      invoice.undo_send!(sender_email(invoice))
    end

    render json: { message: I18n.t('invoices.unsend_all.undo_success', count: unsent.size) }
  end

  def mark_paid
    marked_paid = many_invoices.select do |invoice|
      invoice.mark_paid
    end
    render json: { message: I18n.t('invoices.mark_paid.success', count: marked_paid.count) }
  end

  protected

  def http_auth_token
    # authorize through query string, as this is a pdf page
    if params[:action] == 'print_all'
      params[:auth_token]
    else
      super
    end
  end

  private

  def sanitized_end_date
    @sanitized_end_date ||= TimeSanitizer.input(sanitize_date(:end_date).end_of_day.to_s) rescue nil
  end

  def sanitized_start_date
    @sanitized_start_date ||= TimeSanitizer.input(sanitize_date(:start_date).beginning_of_day.to_s) rescue nil
  end

  def sanitize_date(key)
    TimeSanitizer.output(create_drafts_params[key].to_date)
  end

  def per_page
    params[:per_page].to_i > 0 ? params[:per_page].to_i : 10
  end

  def send_all_params
    { id: params[:invoice_ids] }
  end

  def update_params
    params.require(:invoice).permit(
      custom_invoice_components_attributes: [:id, :price, :name, :vat_decimal, :_destroy],
      invoice_components_attributes: [:id, :_destroy],
      gamepass_invoice_components_attributes: [:id, :_destroy],
      participation_invoice_components_attributes: [:id, :_destroy],
      group_subscription_invoice_components_attributes: [:id, :_destroy],
    )
  end

  def create_drafts_params
    params.permit(:start_date, :end_date, :user_type, :save_users, user_ids: [], coach_ids: [])
  end

  def create_params
    params.permit(:owner_id, :owner_type, custom_invoice_components_attributes: [:price, :name, :vat_decimal])
  end

  def invoice
    @invoice ||= authorized_scope(company.invoices).find(params[:id])
  end

  def many_invoices
    @invomany_invoicesice ||= authorized_scope(company.invoices).
                                where(id: params[:invoice_ids])
  end

  def company
    @company ||= current_admin.company
  end

  def venue
    @venue ||= company.venues.first
  end

  # optional for :create_drafts
  def custom_biller
    @custom_biller ||= params[:custom_biller_id] && company.group_custom_billers.
                                                            find(params[:custom_biller_id])
  end

  def users_to_invoice
    if create_drafts_params[:user_type].present? # we need all users of the type
      OutstandingBalances.new(company, custom_biller).
                          users_by_type(create_drafts_params[:user_type])
    else
      if create_drafts_params[:coach_ids].present?
        company.coaches.where(id: create_drafts_params[:coach_ids])
      elsif create_drafts_params[:user_ids].present?
        company.users.where(id: create_drafts_params[:user_ids])
      end
    end
  end

  def save_to_quick_invoicing(invoiced_users)
    return if invoiced_users.none? || !invoiced_users.first.is_a?(User)

    company.update(
      cached_invoice_period_start: sanitized_start_date,
      cached_invoice_period_end: sanitized_end_date,
      recent_invoice_users: invoiced_users
    )
    company.save_invoice_users(invoiced_users) if create_drafts_params[:save_users].present?
  end

  # will default in the mailer
  def sender_email(invoice)
    case params[:sender]
    when 'company'
      invoice.company.invoice_sender_email
    when 'admin'
      current_admin.email
    when 'custom'
      params[:sender_email]
    else
      nil
    end
  end
end
