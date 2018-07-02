class API::InvoicesController < API::BaseController
  before_action :authenticate_request!
  before_action :set_invoice, only: [:show, :pay]

  def index
    set_invoices
  end

  def pay
    @invoice.charge!(params[:card])
    set_invoices
    render :index
  rescue => e
    render json: e, status: 400
  end

  def show
    @company = @invoice.company
    render 'invoices/show', format: :pdf
  end

  private

  def set_invoice
    @invoice = current_user.invoices.
      viewable_by_user.
      includes(invoice_components: {reservation: {court: :venue}}).
      find(params[:id] || params[:invoice_id])
  end

  def set_invoices
    @invoices = current_user.invoices.
                             viewable_by_user.
                             components_includes.
                             includes(invoice_components: { reservation: [:membership, :user] })
  end
end
