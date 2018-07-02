class CustomInvoiceComponentsController < ApplicationController
  def create
    @invoice = Invoice.find(params[:invoice_id])
    @custom_invoice_component = @invoice.custom_invoice_components.
                                       build(custom_invoice_component_params)

    @invoice.calculate_total! if @custom_invoice_component.save

    respond_to do |format|
      if @custom_invoice_component.errors.any?
        errors = @custom_invoice_component.errors.full_messages
        format.json { render json: errors, status: :unprocessable_entity }
        format.html { redirect_to :back, error: errors.join('; '), status: :unprocessable_entity }
      else
        format.json { render 'invoices/custom_invoice_component', status: :ok }
        format.html { redirect_to :back, notice: I18n.t('invoices.drafts_table.custom_component_created'), status: :ok }
      end
    end
  end

  def destroy
    custom_invoice_component = CustomInvoiceComponent.find(params[:id])

    custom_invoice_component.destroy
    invoice = custom_invoice_component.invoice
    invoice.calculate_total!

    respond_to do |format|
      format.js {
        render text: <<-JS
          $('#custom_invoice_component_#{custom_invoice_component.id}').remove();
          $('.invoice_#{invoice.id}_total').text(#{invoice.total});
        JS
      }
    end
  end

  def vat
    vats = CustomInvoiceComponent::DEFAULT_VAT_DECIMALS.map do |v|
      vat_label = "#{v * 100}%"
      { label: vat_label, value: v }
    end
    render json: vats
  end

  protected

  def custom_invoice_component_params
    params.require(:custom_invoice_component)
          .permit(:price, :name, :vat_decimal)
  end
end
