class InvoiceComponentsController < ApplicationController
  def destroy
    invoice_component = InvoiceComponent.find(params[:id])

    invoice_component.destroy
    invoice = invoice_component.invoice
    invoice.calculate_total!

    respond_to do |format|
      format.js {
        render text: <<-JS
          $('#invoice_component_#{invoice_component.id}').detach();
          $('.invoice_#{invoice.id}_total').text(#{invoice.total});
        JS
      }
    end
  end
end
