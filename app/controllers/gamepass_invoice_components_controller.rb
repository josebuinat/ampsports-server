class GamepassInvoiceComponentsController < ApplicationController
  def destroy
    gamepass_invoice_component = GamepassInvoiceComponent.find(params[:id])

    gamepass_invoice_component.destroy
    invoice = gamepass_invoice_component.invoice
    invoice.calculate_total!

    respond_to do |format|
      format.js {
        render text: <<-JS
          $('#gamepass_invoice_component_#{gamepass_invoice_component.id}').detach();
          $('.invoice_#{invoice.id}_total').text(#{invoice.total});
        JS
      }
    end
  end
end
